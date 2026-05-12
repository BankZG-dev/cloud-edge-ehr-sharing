pragma circom 2.1.4;

include "circomlib/circuits/sha256.circom";
include "circomlib/circuits/comparators.circom";

// Convert a single integer into 160 bits (little-endian)
template Num2Bits160() {
    signal input in;
    signal output out[160];

    var acc = 0;
    var base = 1;
    for (var i = 0; i < 160; i++) {
        out[i] <-- (in >> i) & 1;
        acc += out[i] * base;
        base *= 2;
    }
    in === acc;
}

// Check equality of two field elements: returns 1 if a == b, else 0
template IsEqual() {
    signal input a;
    signal input b;
    signal output out;

    signal diff;
    diff <== a - b;
    out <== 1 - diff * diff;
}

template AccessControlOptimized() {
    // Private inputs
    signal input userID;
    signal input domainCode;
    signal input roleCode;
    signal input random;

    // Public inputs
    signal input threshold;
    signal input precomputedCommitment[2];

    // Outputs
    signal output passed;
    signal output totalWeight;
    signal output commitmentMatch;

    // ── Access check ────────────────────────────────────────────────────────
    // totalWeight = domainCode * 2 + roleCode * 3
    totalWeight <== domainCode * 2 + roleCode * 3;

    // Use GreaterEqThan to check totalWeight >= threshold (16-bit comparison)
    component check = GreaterEqThan(16);
    check.in[0] <== totalWeight;
    check.in[1] <== threshold;
    passed <== check.out;

    // ── Commitment check ─────────────────────────────────────────────────────
    // Pack all values into one 160-bit integer:
    // packed = userID * 10_000_000_000
    //        + domainCode * 100_000_000
    //        + roleCode   * 1_000_000
    //        + random     * 100
    //        + threshold
    signal packed;
    packed <== userID     * 10000000000 +
               domainCode * 100000000   +
               roleCode   * 1000000     +
               random     * 100         +
               threshold;

    // Decompose packed into 160 bits (little-endian)
    component n2b = Num2Bits160();
    n2b.in <== packed;

    // Build 512-bit input for SHA256 (pad with zeros after 160 bits)
    signal inputBits[512];
    for (var i = 0; i < 160; i++) {
        inputBits[i] <== n2b.out[i];
    }
    for (var i = 160; i < 512; i++) {
        inputBits[i] <== 0;
    }

    // Run SHA256
    component sha = Sha256(512);
    for (var i = 0; i < 512; i++) {
        sha.in[i] <== inputBits[i];
    }

    // Reconstruct two 128-bit integers from the 256-bit SHA output
    // SHA256 output is 256 bits; split into two groups of 128 bits
    signal hashPart0;
    signal hashPart1;

    var acc0 = 0;
    var acc1 = 0;
    var base0 = 1;
    var base1 = 1;

    for (var i = 0; i < 128; i++) {
        acc0 += sha.out[i] * base0;
        base0 *= 2;
    }
    for (var i = 128; i < 256; i++) {
        acc1 += sha.out[i] * base1;
        base1 *= 2;
    }

    hashPart0 <== acc0;
    hashPart1 <== acc1;

    // Compare reconstructed hash parts against precomputed commitment
    component eq0 = IsEqual();
    eq0.a <== hashPart0;
    eq0.b <== precomputedCommitment[0];

    component eq1 = IsEqual();
    eq1.a <== hashPart1;
    eq1.b <== precomputedCommitment[1];

    commitmentMatch <== eq0.out * eq1.out;
}

component main { public [threshold, precomputedCommitment] } = AccessControlOptimized();
