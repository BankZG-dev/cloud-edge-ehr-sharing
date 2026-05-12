# Zero-Knowledge Access Control with Circom + snarkjs

> This is the **ZKP component** of the [cloud-edge-pre-zkp](../) project.
> See the root README for the full system overview.

This component demonstrates a zero-knowledge **access control circuit** built with **Circom** and proven using **snarkjs** (PLONK proving system + Pedersen commitments).

Two circuit versions are included:

- `access_control_normal.circom` — baseline design (reference only)
- `access_control_optimized.circom` — constraint-optimized version (used in the pipeline)

Solidity verifiers are provided to show compatibility with EVM smart contracts.

---

## ⚠️ Platform Warning

The `npm run plonk` script uses **Windows-only** commands (`rmdir /s /q`).

**On Mac/Linux**, edit `package.json` and replace:
```json
"rmdir /s /q build"
```
with:
```json
"rm -rf build"
```
Then run `npm run plonk` as normal.

**On Windows**, no changes needed — run as-is using CMD (not PowerShell).

---

## Prerequisites

You must install **circom** and **snarkjs** before running this project.

### 1) Install Rust (required for circom)

https://www.rust-lang.org/tools/install

After installing Rust, restart your terminal.

### 2) Install circom

```bash
cargo install --git https://github.com/iden3/circom.git
```

Verify:

```bash
circom --version
```

### 3) Install snarkjs

```bash
npm install -g snarkjs
```

Verify:

```bash
snarkjs --version
```

---

## Install Project Dependencies

Inside the `zkp/` folder:

```bash
npm install
```

---

## Run the Full Proof Pipeline

> ℹ️ This pipeline runs the **optimized circuit only** (`access_control_optimized.circom`).
> The normal circuit (`access_control_normal.circom`) is included for comparison purposes and does not have a dedicated run script.

```bash
npm run plonk
```

This single command will:

1. Delete any previous `build/` folder
2. Compile `access_control_optimized.circom` → R1CS + WASM
3. Run Powers of Tau (single contributor — suitable for learning/demo only, not production)
4. Perform PLONK setup → generate `access_control.zkey`
5. Export verification key → `verification_key.json`
6. Generate witness from `input_optimized.json`
7. Generate a proof → `proof.json` + `public.json`
8. Verify the proof

If everything is correct, you will see:

```
OK!
```

at the end of the verification step.

---

## Circuit Inputs

The optimized circuit (`access_control_optimized.circom`) expects the following inputs in `input_optimized.json`:

| Input | Type | Description |
|---|---|---|
| `userID` | private | User identifier |
| `random` | private | Randomness for Pedersen commitment |
| `domainCode` | private | Numeric code representing user's domain |
| `roleCode` | private | Numeric code representing user's role |
| `threshold` | public | Minimum attribute weight required for access |

Access is granted when: `(domainCode × 2) + (roleCode × 3) >= threshold`

The `input_optimized.json` file is already included in the repo — no need to regenerate it unless you want to test different input values. To regenerate:

```bash
node generate_input_optimized.js
```

---

## Project Structure

```
zkp/
├── circuits/
│   ├── access_control_normal.circom      ← baseline (reference only)
│   └── access_control_optimized.circom   ← used in pipeline
│
├── verifier.sol                          ← Solidity verifier (optimized)
├── verifier_normal.sol                   ← Solidity verifier (normal)
│
├── generate_input.js                     ← generates input.json
├── generate_input_optimized.js           ← generates input_optimized.json
├── input.json                            ← inputs for normal circuit
├── input_optimized.json                  ← inputs for optimized circuit
│
├── package.json
├── package-lock.json
└── README.md
```

---

## Why build artifacts are NOT included

This repository intentionally does **not** include:

- `.ptau` files
- `.zkey` files
- `/build` folder
- witness files (`witness.wtns`)
- proof files (`proof.json`, `public.json`)

These files are large, machine-generated, and fully reproducible from the circuit source.
Keeping them out makes the repository clean and reproducible.

---

## Regenerating the Solidity Verifier

After running the pipeline, you can regenerate the Solidity verifier:

```bash
snarkjs zkey export solidityverifier build/access_control.zkey verifier.sol
```

---

## Notes

- Designed for reproducibility and learning
- The Powers of Tau ceremony uses a **single contributor** — not suitable for production use
- Shows both baseline and optimized circuit design side by side
- Demonstrates compatibility with on-chain verification (EVM)
- Uses PLONK proving system with Pedersen commitments for privacy-preserving attribute verification