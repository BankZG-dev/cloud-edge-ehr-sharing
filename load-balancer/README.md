# Auto Scaling & Load Balance Algorithm for Distributed Proxy Re-Encryption System

> This is the **Load Balancer component** of the [cloud-edge-pre-zkp](../) project.
> See the root README for the full system overview.

A Kubernetes‐based proxy that auto‐scales and distributes Python job uploads to worker pods for re‐encryption.

## Table of Contents

1. [About](#about)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Load Testing](#load-testing)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)

---

## About

Distributed PRE (Proxy Re‐Encryption) Load Balancer lets you upload an executable file to a single Kubernetes custom load balancer service (`proxy-master`). The master automatically chooses a worker pod to run re‐encryption jobs based on the workers' computation resource usage. As demand fluctuates, Horizontal Pod Autoscaler (`HPA`) spins worker pods up/down so that each job is handled promptly without manual intervention.

In the context of the full system, this component receives re-encryption requests **after** the ZKP component has verified the user's access credentials on the Hyperledger Fabric blockchain.

---

## Features

- Single "front‐door" API (`/reencrypt`) for clients to upload Python files.
- Master proxy polls worker pods' resource usage via the Kubernetes Metrics API.
- Master automatically picks the least computation resource consumption worker.
- FastAPI + aiohttp based forwarding (non‐blocking).
- Worker pods run the uploaded Python script in a subprocess, then return stdout/stderr.
- Kubernetes manifests included: Deployments, Headless Service for workers, HPA spec.
- Simple Python load‐tester script (`throughputtest.py`) to measure throughput and latency under various concurrency levels.

---

## Prerequisites

- A Kubernetes cluster (version ≥ 1.24) with Metrics Server installed.
- `kubectl` configured to talk to your cluster.
- Docker (for building the `proxy-master` and `proxy-worker` images).
- Python 3.9+ installed locally (for running the load‐tester and building images).
- (Optional) `gcloud` or other cloud‐CLI if you're using a managed Kubernetes service (e.g. GKE).

---

## Installation

### Build & Push Docker Images

```bash
# 1. Build the Worker image
cd src/K8s_node_worker
docker build -t <YOUR_REGISTRY>/proxy-worker-node:v1 .
docker push <YOUR_REGISTRY>/proxy-worker-node:v1

# 2. Build the Master image
cd ../K8s_node_master
docker build -t <YOUR_REGISTRY>/proxy-master-node:v1 .
docker push <YOUR_REGISTRY>/proxy-master-node:v1
```

### Apply Kubernetes Manifests

```bash
cd ../K8s_config

# 1. Create RBAC for master
kubectl apply -f proxy-master-rbac.yaml

# 2. Deploy the master
kubectl apply -f proxy-master-deploy.yaml
kubectl apply -f proxy-master-svc.yaml

# 3. Deploy the workers
kubectl apply -f proxy-worker-deploy.yaml
kubectl apply -f proxy-worker-svc.yaml

# 4. Set up HPA to auto‐scale worker pods
kubectl apply -f proxy-worker-hpa.yaml

# 5. Install Metrics-Server (if not yet installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Verify All Deployments & Services

```bash
# 1. Check Workers Deployment Status and Pods
kubectl get deployment proxy-worker
kubectl get pods -l app=proxy-worker

# 2. Check HPA service (wait until "TARGETS" cpu and ram percentage are shown before testing)
kubectl get hpa proxy-worker-hpa -w

# 3. Check Master Deployment Status and Pods
kubectl get deployment proxy-master
kubectl get pods -l app=proxy-master

# 4. Get Master External IP
kubectl get svc proxy-master-svc -w

# 5. Confirm Master RBAC Deployment
kubectl get sa proxy-master-sa
kubectl get clusterrole proxy-master-metrics-reader
kubectl get clusterrolebinding proxy-master-metrics-reader-binding

# 6. Verify correct service account (should output "proxy-master-sa")
kubectl get deployment proxy-master -n default -o jsonpath="{.spec.template.spec.serviceAccountName}"

# 7. (Optional) If service account is wrong, run:
kubectl set serviceaccount deployment proxy-master proxy-master-sa -n default
kubectl rollout restart deployment proxy-master

# 8. Test Metrics Server is working
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
kubectl top nodes
kubectl top pods --all-namespaces
```

---

## Usage

### 1. Master API Endpoints

```bash
cd src/K8s_request

# POST /reencrypt: upload a .py Python script for re‐encryption
curl -X POST -F "file=@my_script.py" http://<MASTER_EXTERNAL_IP>/reencrypt
```

The response `JSON` includes:
- `"returncode"`, `"stdout"`, `"stderr"`

### 2. Worker API Endpoints

- `POST /reencrypt` — (master → worker) receives the file, executes it, returns JSON.

---

## Load Testing

Use the bundled `throughputtest.py` script to benchmark:

```bash
# Example: 1000 concurrent requests, 10000 total
python src/K8s_request/throughputtest.py \
  --url http://<MASTER_EXTERNAL_IP>/reencrypt \
  --file my_script.py \
  --total 10000 \
  --concurrent 1000
```

| Flag | Description |
|---|---|
| `--total` | Total number of requests |
| `--concurrent` | How many simultaneous requests to keep in flight |

Results show: `Total`, `Successful`, `Failed`, `Total Time (s)`, `Throughput (req/s)`, Latency `p50`/`p95`/`p99`.

---

## Configuration

| File | What to configure |
|---|---|
| `proxy-worker-deploy.yaml` | Worker CPU & memory limits, starting number of worker replicas (default=1) |
| `proxy-worker-hpa.yaml` | HPA spec — average CPU%, memory%, min/max worker count |
| `proxy-master-deploy.yaml` | Uvicorn workers, master resource limits |

### Adjusting Master → Worker Timeout

In `K8s_node_master/master_app.py`:

```python
# Set timeout in seconds (e.g. 200s)
async with session.post(f"{worker_url}/reencrypt", data=form, timeout=200) as resp:

# Or set to None for no timeout
async with session.post(f"{worker_url}/reencrypt", data=form, timeout=None) as resp:
```

---

## Troubleshooting

### 1. 502 Bad Gateway from master
- Master → Worker timeout too low — increase timeout value.
- Worker pods not running or mis‐labeled — check `kubectl get pods -l app=proxy-worker`.
- Missing RBAC — apply `proxy-master-rbac.yaml` and ensure Deployment uses `serviceAccountName: proxy-master-sa`.

### 2. Load‐test failures
- Client hitting ephemeral port limit or file descriptor limit — use WSL2/Linux and run `ulimit -n 65535`.
- Concurrency too high — workers queue too deep, increase worker CPU or replicas.

### 3. Metrics not found
- `"pods.metrics.k8s.io forbidden"` — RBAC is missing or the wrong ServiceAccount is assigned. Re-apply `proxy-master-rbac.yaml`.