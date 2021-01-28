#!/bin/bash -e
npx circom -rwv BatchTreeUpdate.circom
zkutil setup -c BatchTreeUpdate.r1cs -p BatchTreeUpdate.params
zkutil generate-verifier -p BatchTreeUpdate.params -v ../build/circuits/BatchTreeUpdateVerifier.sol
