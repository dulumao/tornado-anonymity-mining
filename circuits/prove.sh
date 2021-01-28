#!/bin/bash -e
node input.js
npx snarkjs wd BatchTreeUpdate.wasm
npx snarkjs wej
zkutil prove -c BatchTreeUpdate.r1cs -p BatchTreeUpdate.params
zkutil verify -p BatchTreeUpdate.params