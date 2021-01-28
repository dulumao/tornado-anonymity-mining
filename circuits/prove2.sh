#!/bin/bash -e
## put non-hashed inputs into input_raw.json
node input_prod.js
npx snarkjs wd Utils.wasm
npx snarkjs wej
zkutil prove -c Utils.r1cs -p Utils.params
zkutil verify -p Utils.params