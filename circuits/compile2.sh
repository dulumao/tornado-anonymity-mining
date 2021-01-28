#!/bin/bash -e
npx circom -rwsv Utils.circom
zkutil setup -c Utils.r1cs -p Utils.params
zkutil generate-verifier -p Utils.params -v ../build/circuits/UtilsVerifier.sol
