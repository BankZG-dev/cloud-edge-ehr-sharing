pragma circom 2.0.0;

include "circomlib/circuits/pedersen.circom";
include "circomlib/circuits/comparators.circom";

template AccessControl() {
    // Private inputs
    signal input userID;
    signal input random;
    signal input domainCode;
    signal input roleCode;

    // Public input
    signal input threshold;

    // ✅ Declare outputs at the top
    signal output passed;
    signal output commitmentX;
    signal output commitmentY;

    // Compute attribute weight
    signal domainWeight;
    signal roleWeight;
    signal totalWeight;
    domainWeight <== domainCode * 2;
    roleWeight <== roleCode * 3;
    totalWeight <== domainWeight + roleWeight;

    // Compare totalWeight >= threshold
    component check = GreaterEqThan(16);
    check.in[0] <== totalWeight;
    check.in[1] <== threshold;
    passed <== check.out;
    assert(passed == 1);

    // Encode identity
    signal inputData;
    inputData <== userID + domainCode * 1000000 + roleCode * 100000000;

    // Bit decomposition for Pedersen
    signal inputBits[32];
    signal randBits[64];
    signal qInput[32];
    signal qRand[64];
    signal allBits[96];

    var tmp;
    tmp = inputData;
    for (var i = 0; i < 32; i++) {
        qInput[i] <-- tmp / 2;
        inputBits[i] <== tmp - qInput[i] * 2;
        tmp = qInput[i];
    }

    tmp = random;
    for (var i = 0; i < 64; i++) {
        qRand[i] <-- tmp / 2;
        randBits[i] <== tmp - qRand[i] * 2;
        tmp = qRand[i];
    }

    for (var i = 0; i < 32; i++) {
        allBits[i] <== inputBits[i];
    }
    for (var i = 0; i < 64; i++) {
        allBits[32 + i] <== randBits[i];
    }

    component ped = Pedersen(96);
    for (var i = 0; i < 96; i++) {
        ped.in[i] <== allBits[i];
    }

    // ✅ Assign outputs (AFTER declaration!)
    commitmentX <== ped.out[0];
    commitmentY <== ped.out[1];
}

template Wrapper() {
    signal input userID;
    signal input domainCode;
    signal input roleCode;
    signal input random;
    signal input threshold;

    component inner = AccessControl();
    inner.userID <== userID;
    inner.domainCode <== domainCode;
    inner.roleCode <== roleCode;
    inner.random <== random;
    inner.threshold <== threshold;

    // Public outputs
    signal output commitmentX;
    signal output commitmentY;
    signal output passed;
    signal output threshold_out;

    commitmentX <== inner.commitmentX;
    commitmentY <== inner.commitmentY;
    passed <== inner.passed;
    threshold_out <== threshold;
}

component main = Wrapper();