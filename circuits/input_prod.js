const fs = require('fs')
const jsSHA = require("jssha")
const { toBN } = require('web3-utils')

function hashInputs(input) {
  const sha = new jsSHA("SHA-256", "ARRAYBUFFER")
  sha.update(toBN(input.oldRoot).toBuffer('be', 32))
  sha.update(toBN(input.newRoot).toBuffer('be', 32))
  sha.update(toBN(input.pathIndices).toBuffer('be', 1))

  for (let i = 0; i < input.instances.length; i++) {
    sha.update(toBN(input.instance).toBuffer('be', 20))
    sha.update(toBN(input.hash).toBuffer('be', 32))
    sha.update(toBN(input.block).toBuffer('be', 4))
  }

  return sha.getHash("HEX")
}

const hash = hashInputs(require('./input_raw.json'))
console.log(hash)
fs.writeFileSync('input.json', JSON.stringify({ argsHash: hash }))