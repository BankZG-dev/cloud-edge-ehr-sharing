# cloud-edge-pre-zkp

A secure and scalable cross-domain Electronic Health Record (EHR) sharing framework combining **Zero-Knowledge Proofs (ZKP)** for privacy-preserving access control and an **Auto-Scaling Load Balancer** for distributed Proxy Re-Encryption (PRE) proxies.

This repository contains the implementation for the paper:

> **Scalable and Privacy-Preserving Cloud-Edge Data Sharing Architecture Accelerating Re-Encryption with Auto-Scaling Proxies and Precomputed zkSNARKs**
> Harid Nutkumhang, Krittin Limotai, Jenwit Thitikawin, Peerapong Vipittragran
> Sirindhorn International Institute of Technology, Thammasat University, Thailand
> 
> 📄 [Read the full paper](./paper.pdf)
---

## System Overview

The system is designed around a cloud-edge model for secure EHR sharing across organizational boundaries. It is composed of two core components:

| Component | Description |
|---|---|
| [zkp/](./zkp/) | Zero-Knowledge Proof access control circuit using Circom + snarkjs (Groth16 + Pedersen commitments) |
| [load-balancer/](./load-balancer/) | Auto-scaling distributed PRE proxy system deployed on Kubernetes (GKE) |

### How They Work Together

1. A Data User (DU) generates a ZKP of their role and domain using the ZKP component.
2. The proof is submitted to a Hyperledger Fabric smart contract for verification.
3. Upon successful verification, the Load Balancer's Master Proxy assigns the re-encryption task to the least-loaded Worker Proxy.
4. The Worker Proxy performs AB-PRE re-encryption, allowing the DU to decrypt the EHR.

---

## Repository Structure

```
cloud-edge-pre-zkp/
├── README.md                  ← You are here
├── zkp/                       ← ZKP access control circuit
│   ├── README.md
│   ├── circuits/
│   ├── verifier.sol
│   ├── verifier_normal.sol
│   ├── generate_input.js
│   ├── generate_input_optimized.js
│   ├── input.json
│   ├── input_optimized.json
│   └── package.json
│
└── load-balancer/             ← Auto-scaling distributed PRE proxy
    ├── README
    └── src/
        ├── K8s_config/
        ├── K8s_node_master/
        ├── K8s_node_worker/
        └── K8s_request/
```

---

## Quick Start

### ZKP Component

```bash
cd zkp
npm install
npm run plonk
```

See [zkp/README.md](./zkp/README.md) for full setup instructions including Circom and snarkjs installation.

### Load Balancer Component

```bash
cd load-balancer/src
docker build -t <YOUR_REGISTRY>/proxy-worker-node:v1 K8s_node_worker/
docker build -t <YOUR_REGISTRY>/proxy-master-node:v1 K8s_node_master/
kubectl apply -f K8s_config/
```

See [load-balancer/README](./load-balancer/README) for full Kubernetes deployment instructions.

---

## Key Results

- ZKP precomputation reduced proving time bottlenecks by up to **6%** with more stable performance.
- Our load-aware distributed proxy achieved **100% request success** at 1,000 concurrent users vs. 1,375 failures with a traditional random load balancer.
- Throughput peaked at **16.9 req/s** vs. 9.1 req/s for the traditional model.
- p95 latency at high concurrency: **225,000 ms** vs. 285,000 ms for the random balancer.

---

## Tech Stack

- **ZKP:** Circom, snarkjs, Groth16, Pedersen Commitments, Solidity
- **Load Balancer:** Python, FastAPI, Docker, Kubernetes (GKE), Horizontal Pod Autoscaler
- **Blockchain:** Hyperledger Fabric, Smart Contracts
- **Encryption:** Attribute-Based Proxy Re-Encryption (AB-PRE), CP-ABE
