include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "./MerkleTreeUpdater.circom";

template TreeLayer(width) {
  signal input ins[1 << (width + 1)];
  signal input outs[1 << width];

  component hash[1 << width];
  for(var i = 0; i < (1 << width); i++) {
    hash[i] = HashLeftRight();
    hash[i].left <== ins[i * 2];
    hash[i].right <== ins[i * 2 + 1];
    hash[i].hash ==> outs[i];
  }
}

// inserts a leaf batch into a tree
// checks that tree previously contained zero leaves in the same position
template BatchTreeUpdate(levels, batchLevels, zeroBatchLeaf) {
  var height = levels - batchLevels;
  var nLeaves = 1 << batchLevels;
  signal input argsHash;
  signal private input oldRoot;
  signal private input newRoot;
  signal private input pathIndices;
  signal private input pathElements[height];
  signal private input instances[nLeaves];
  signal private input hashes[nLeaves];
  signal private input blocks[nLeaves];

  var bitsPerLeaf = 160 + 248 + 32;
  component hasher = Sha256(nLeaves * bitsPerLeaf);
  component bitsInstance[nLeaves];
  component bitsHash[nLeaves];
  component bitsBlock[nLeaves];
  for(var leaf = 0; leaf < nLeaves; leaf++) {
    bitsInstance[leaf] = Num2Bits(160);
    bitsHash[leaf] = Num2Bits(248);
    bitsBlock[leaf] = Num2Bits(32);
    bitsInstance[leaf].in <== instances[leaf];
    bitsHash[leaf].in <== hashes[leaf];
    bitsBlock[leaf].in <== blocks[leaf];
    for(var i = 0; i < 160; i++) {
      hasher.in[leaf * bitsPerLeaf + i] <== bitsInstance[leaf].out[i];
    }
    for(var i = 0; i < 248; i++) {
      hasher.in[leaf * bitsPerLeaf + i + 160] <== bitsHash[leaf].out[i];
    }
    for(var i = 0; i < 32; i++) {
      hasher.in[leaf * bitsPerLeaf + i + 308] <== bitsBlock[leaf].out[i];
    }
  }
  component b2n = Bits2Num(248);
  for (var i = 0; i < 248; i++) {
      b2n.in[i] <== hasher.out[i];
  }
  argsHash === b2n.out;

  component leaves[nLeaves];
  for(var i = 0; i < nLeaves; i++) {
    leaves[i] = Poseidon(3);
    leaves[i].inputs[0] <== instances[i];
    leaves[i].inputs[1] <== hashes[i];
    leaves[i].inputs[2] <== blocks[i];
  }

  component layers[batchLevels];
  for(var level = batchLevels - 1; level >= 0; level--) {
    layers[level] = TreeLayer(level);
    for(var i = 0; i < (1 << (level + 1)); i++) {
      layers[level].ins[i] <== level == batchLevels - 1 ? leaves[i].out : layers[level + 1].outs[i];
    }
  }

  component treeUpdater = MerkleTreeUpdater(height, zeroBatchLeaf);
  treeUpdater.oldRoot <== oldRoot;
  treeUpdater.newRoot <== newRoot;
  treeUpdater.leaf <== layers[0].outs[0];
  treeUpdater.pathIndices <== pathIndices;
  for(var i = 0; i < height; i++) {
    treeUpdater.pathElements[i] <== pathElements[i];
  }
}

// zeroLeaf = keccak256("tornado") % FIELD_SIZE
// zeroBatchLeaf is poseidon(zeroLeaf, zeroLeaf) (batchLevels - 1) times
component main = BatchTreeUpdate(20, 2, 21572503925325825116380792768937986743990254033176521064707045559165336555197)

// for mainnet use 20, 7, 17278668323652664881420209773995988768195998574629614593395162463145689805534

/*
zeros of n-th order:
21663839004416932945382355908790599225266501822907911457504978515578255421292
11850551329423159860688778991827824730037759162201783566284850822760196767874
21572503925325825116380792768937986743990254033176521064707045559165336555197
11224495635916644180335675565949106569141882748352237685396337327907709534945
 2399242030534463392142674970266584742013168677609861039634639961298697064915
13182067204896548373877843501261957052850428877096289097123906067079378150834
 7106632500398372645836762576259242192202230138343760620842346283595225511823
17278668323652664881420209773995988768195998574629614593395162463145689805534
  209436188287252095316293336871467217491997565239632454977424802439169726471
 6509061943359659796226067852175931816441223836265895622135845733346450111408
*/
