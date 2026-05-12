const fs = require("fs");
const crypto = require("crypto");

// ── Input values ─────────────────────────────────────────────────────────────
const userID     = 123;
const domainCode = 2;       // domainWeight = 2 * 2 = 4
const roleCode   = 1;       // roleWeight   = 3 * 1 = 3
const random     = 987654321;
const threshold  = 7;       // totalWeight = 4 + 3 = 7 → passes (>= threshold)

// ── Replicate circuit packing ─────────────────────────────────────────────────
// Must match exactly what the circuit does:
// packed = userID * 10_000_000_000
//        + domainCode * 100_000_000
//        + roleCode   * 1_000_000
//        + random     * 100
//        + threshold
const packed = BigInt(userID)     * 10000000000n +
               BigInt(domainCode) * 100000000n   +
               BigInt(roleCode)   * 1000000n      +
               BigInt(random)     * 100n          +
               BigInt(threshold);

// ── Decompose into 160 bits little-endian (matches Num2Bits160 in circuit) ────
const bits = [];
let tmp = packed;
for (let i = 0; i < 160; i++) {
    bits.push(Number(tmp & 1n));
    tmp >>= 1n;
}

// ── Pad to 512 bits and convert to bytes for SHA256 ──────────────────────────
// Circomlib Sha256 takes bits MSB-first per byte
const inputBits512 = [...bits, ...new Array(352).fill(0)];
const bytes = [];
for (let i = 0; i < 64; i++) {
    let byte = 0;
    for (let j = 0; j < 8; j++) {
        byte = (byte << 1) | inputBits512[i * 8 + j];
    }
    bytes.push(byte);
}

// ── Compute SHA256 ────────────────────────────────────────────────────────────
const hash = crypto.createHash("sha256").update(Buffer.from(bytes)).digest();

// ── Split into two 128-bit integers ──────────────────────────────────────────
// precomputedCommitment[0] = first  128 bits (bytes 0–15)
// precomputedCommitment[1] = second 128 bits (bytes 16–31)
const part0 = BigInt("0x" + hash.slice(0, 16).toString("hex")).toString();
const part1 = BigInt("0x" + hash.slice(16).toString("hex")).toString();

// ── Write input JSON ──────────────────────────────────────────────────────────
const inputJson = {
    userID,
    domainCode,
    roleCode,
    random,
    threshold,
    precomputedCommitment: [part0, part1]
};

fs.writeFileSync("input_optimized.json", JSON.stringify(inputJson, null, 2));
console.log("✅ input_optimized.json generated successfully!");
console.log("   precomputedCommitment[0]:", part0);
console.log("   precomputedCommitment[1]:", part1);
