include "../node_modules/circomlib/circuits/poseidon.circom";
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

  signal input oldRoot;
  signal input newRoot;
  signal input pathIndices;
  signal private input pathElements[height];
  signal input instances[1 << batchLevels];
  signal input hashes[1 << batchLevels];
  signal input blocks[1 << batchLevels];

  component leaves[1 << batchLevels];
  for(var i = 0; i < (1 << batchLevels); i++) {
    leaves[i] = Poseidon(3);
    leaves[i].inputs[0] <== instances[i];
    leaves[i].inputs[1] <== hashes[i];
    leaves[i].inputs[2] <== blocks[i];
  }

  component layers[batchLevels];
  // level var wraps around 0
  for(var level = batchLevels - 1; level < batchLevels; level--) {
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
component main = BatchTreeUpdate(20, 7, 7106632500398372645836762576259242192202230138343760620842346283595225511823)

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
