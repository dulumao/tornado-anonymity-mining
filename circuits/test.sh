#!/bin/bash -e
../../node/out/Release/node --trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 ../../circom/cli.js circuit.circom -f -r -v -w
node input.js
snarkjs wc
snarkjs wej
zkutil setup
zkutil prove
zkutil verify
snarkjs info