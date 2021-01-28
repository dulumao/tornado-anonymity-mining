#!/bin/bash -e
## put non-hashed inputs into input_raw.json
node input_prod.json
npx snarkjs wc
npx snarkjs wej
zkutil prove -c BatchTreeUpdate.r1cs -p BatchTreeUpdate.params
zkutil verify -p BatchTreeUpdate.params