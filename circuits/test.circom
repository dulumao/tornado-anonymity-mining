include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/sha256/sha256.circom";

template test1() {
  signal input in;
  signal output out;

  component n2b = Num2Bits(248);
  component sha = Sha256(248);
  n2b.in <== in;
  for (var i = 0; i < 248; i++) {
      sha.in[i] <== n2b.out[247 - i];
  }

  component b2n = Bits2Num(248);
  for (var i = 0; i < 248; i++) {
      b2n.in[i] <== sha.out[255 - i];
  }
  out <== b2n.out;
}

component main = test1();