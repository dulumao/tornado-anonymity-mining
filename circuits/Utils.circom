include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "../node_modules/circomlib/circuits/sha256/sha256.circom";

// computes Pedersen(nullifier + secret)
template TornadoCommitmentHasher() {
    signal input nullifier;
    signal input secret;
    signal output commitment;
    signal output nullifierHash;

    component commitmentHasher = Pedersen(496);
    component nullifierHasher = Pedersen(248);
    component nullifierBits = Num2Bits(248);
    component secretBits = Num2Bits(248);
    nullifierBits.in <== nullifier;
    secretBits.in <== secret;
    for (var i = 0; i < 248; i++) {
        nullifierHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i + 248] <== secretBits.out[i];
    }

    commitment <== commitmentHasher.out[0];
    nullifierHash <== nullifierHasher.out[0];
}

template TreeUpdateArgsHasher(nLeaves) {
    signal private input oldRoot;
    signal private input newRoot;
    signal private input pathIndices;
    signal private input instances[nLeaves];
    signal private input hashes[nLeaves];
    signal private input blocks[nLeaves];
    signal output out;

    var header = 256 + 256 + 8;
    var bitsPerLeaf = 160 + 256 + 32;
    component hasher = Sha256(header + nLeaves * bitsPerLeaf);

    component bitsOldRoot[256] = Num2Bits(256);
    component bitsNewRoot[256] = Num2Bits(256);
    component bitsPathIndices[8] = Num2Bits(8);
    component bitsInstance[nLeaves];
    component bitsHash[nLeaves];
    component bitsBlock[nLeaves];
    
    bitsOldRoot.in <== oldRoot;
    bitsNewRoot.in <== newRoot;
    bitsPathIndices.in <== pathIndices;
    for(var i = 0; i < 256; i++) {
        hasher.in[i] <== bitsOldRoot.out[255 - i];
    }
    for(var i = 0; i < 256; i++) {
        hasher.in[i + 256] <== bitsNewRoot.out[255 - i];
    }
    for(var i = 0; i < 8; i++) {
        hasher.in[i + 512] <== bitsPathIndices.out[7 - i];
    }
    for(var leaf = 0; leaf < nLeaves; leaf++) {
        bitsInstance[leaf] = Num2Bits(160);
        bitsHash[leaf] = Num2Bits(256);
        bitsBlock[leaf] = Num2Bits(32);
        bitsInstance[leaf].in <== instances[leaf];
        bitsHash[leaf].in <== hashes[leaf];
        bitsBlock[leaf].in <== blocks[leaf];
        for(var i = 0; i < 160; i++) {
            hasher.in[header + leaf * bitsPerLeaf + i] <== bitsInstance[leaf].out[159 - i];
        }
        for(var i = 0; i < 256; i++) {
            hasher.in[header + leaf * bitsPerLeaf + i + 160] <== bitsHash[leaf].out[255 - i];
        }
        for(var i = 0; i < 32; i++) {
            hasher.in[header + leaf * bitsPerLeaf + i + 416] <== bitsBlock[leaf].out[31 - i];
        }
    }
    component b2n = Bits2Num(256);
    for (var i = 0; i < 256; i++) {
        b2n.in[i] <== hasher.out[255 - i];
    }
    out <== b2n.out;
}