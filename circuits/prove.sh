#!/bin/bash -e
## put non-hashed inputs into input_raw.json
node input_prod.js
npx snarkjs wc BatchTreeUpdate.wasm || npx snarkjs wd BatchTreeUpdate.wasm
npx snarkjs wej
zkutil prove -c BatchTreeUpdate.r1cs -p BatchTreeUpdate.params
zkutil verify -p BatchTreeUpdate.params