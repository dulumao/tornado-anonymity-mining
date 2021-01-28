const fs = require('fs')
const jsSHA = require('jssha')
const { toBN } = require('web3-utils')
const MerkleTree = require('fixed-merkle-tree')
const { poseidonHash2, poseidonHash } = require('../src/utils')
const Controller = require('../src/controller')
const contoller = new Controller()

function hashInputs(input) {
  const sha = new jsSHA('SHA-256', 'ARRAYBUFFER')
  sha.update(toBN(input.oldRoot).toBuffer('be', 32))
  sha.update(toBN(input.newRoot).toBuffer('be', 32))
  sha.update(toBN(input.pathIndices).toBuffer('be', 1))

  for (let i = 0; i < input.instances.length; i++) {
    sha.update(toBN(input.instances[i]).toBuffer('be', 20))
    sha.update(toBN(input.hashes[i]).toBuffer('be', 32))
    sha.update(toBN(input.blocks[i]).toBuffer('be', 4))
  }

  const hash = sha.getHash('HEX')
  const result = toBN(hash).mod(toBN('21888242871839275222246405745257275088548364400416034343698204186575808495617')).toString()
  return result
}

const tree = new MerkleTree(20, [], { hashFunction: poseidonHash2 })
const leaves = [
  {
    instance: '0x3535249DFBb73e21c2aCDC6e42796d920A0379b7',
    hash: '0x8d5d6393dda443b4f2ad47562908899c5ff8cfe271ac4c55f1e2cafcb58f97',
    block: 1
  },
  {
    instance: '0x3535249DFBb73e21c2aCDC6e42796d920A0379b7',
    hash: '0x8d5d6393dda443b4f2ad47562908899c5ff8cfe271ac4c55f1e2cafcb58f97',
    block: 2
  },
  {
    instance: '0x3535249DFBb73e21c2aCDC6e42796d920A0379b8',
    hash: '0x8d5d6393dda443b4f2ad47562908899c5ff8cfe271ac4c55f1e2cafcb58f98',
    block: 3
  },
  {
    instance: '0x3535249DFBb73e21c2aCDC6e42796d920A0379b9',
    hash: '0x8d5d6393dda443b4f2ad47562908899c5ff8cfe271ac4c55f1e2cafcb58f98',
    block: 4
  },
]

const input = contoller.batchTreeUpdate(tree, leaves)
console.log(input)

const hash = hashInputs(input)
console.log('hash: ', hash)
input.argsHash = hash
fs.writeFileSync('input.json', JSON.stringify(input, null, 2))