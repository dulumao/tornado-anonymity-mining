/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()
const fs = require('fs')
const { takeSnapshot, revertSnapshot } = require('../scripts/ganacheHelper')
const Note = require('../src/note')
const Controller = require('../src/controller')
const TornadoTrees = artifacts.require('TornadoTreesMock')
const BatchTreeUpdateVerifier = artifacts.require('BatchTreeUpdateVerifier')
const provingKeys = {
  batchTreeUpdateCircuit: require('../build/circuits/BatchTreeUpdate.json'),
  batchTreeUpdateProvingKey: fs.readFileSync('./build/circuits/BatchTreeUpdate_proving_key.bin').buffer,
}

const { toFixedHex, poseidonHash2 } = require('../src/utils')
const MerkleTree = require('fixed-merkle-tree')

async function registerDeposit(note, tornadoTrees, from) {
  await tornadoTrees.setBlockNumber(note.depositBlock)
  await tornadoTrees.registerDeposit(note.instance, toFixedHex(note.commitment), { from })
  return {
    instance: note.instance,
    hash: toFixedHex(note.commitment),
    block: toFixedHex(note.depositBlock),
  }
}

async function registerWithdrawal(note, tornadoTrees, from) {
  await tornadoTrees.setBlockNumber(note.withdrawalBlock)
  await tornadoTrees.registerWithdrawal(note.instance, toFixedHex(note.nullifierHash), { from })
  return {
    instance: note.instance,
    hash: toFixedHex(note.nullifierHash),
    block: toFixedHex(note.withdrawalBlock),
  }
}

const levels = 20
const CHUNK_TREE_HEIGHT = 2
contract.only('TornadoTrees', (accounts) => {
  let tornadoTrees
  let verifier
  let controller
  let snapshotId
  let tornadoProxy = accounts[1]
  let operator = accounts[2]

  const instances = [
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000002',
    '0x0000000000000000000000000000000000000003',
    '0x0000000000000000000000000000000000000004',
  ]

  const notes = []

  before(async () => {
    const emptyTree = new MerkleTree(levels, [], { hashFunction: poseidonHash2 })
    verifier = await BatchTreeUpdateVerifier.new()
    tornadoTrees = await TornadoTrees.new(
      operator,
      tornadoProxy,
      verifier.address,
      toFixedHex(emptyTree.root()),
      toFixedHex(emptyTree.root()),
    )

    for (let i = 0; i < 2 ** CHUNK_TREE_HEIGHT; i++) {
      console.log('i', i)
      notes[i] = new Note({
        instance: instances[i % instances.length],
        depositBlock: 1 + i,
        withdrawalBlock: 2 + i + i * 4 * 60 * 24,
      })
      await registerDeposit(notes[i], tornadoTrees, tornadoProxy)
      await registerWithdrawal(notes[i], tornadoTrees, tornadoProxy)
    }

    controller = new Controller({
      contract: '',
      tornadoTreesContract: tornadoTrees,
      merkleTreeHeight: levels,
      provingKeys,
    })
    await controller.init()

    snapshotId = await takeSnapshot()
  })

  describe('#updateDepositTree', () => {
    it('should work', async () => {
      const emptyTree = new MerkleTree(levels, [], { hashFunction: poseidonHash2 })
      const events = notes.map((note) => ({
        instance: note.instance,
        hash: note.commitment,
        block: note.depositBlock,
      }))
      const data = await controller.batchTreeUpdate(emptyTree, events)
      console.log('data', data)
      console.log('events', data.args[3])
      const recipet = await tornadoTrees.updateDepositTree(data.proof, ...data.args)
      console.log('recipet', recipet)

      // todo validation
    })
  })

  // describe('#getRegisteredDeposits', () => {
  //   it('should work', async () => {
  //     const note1DepositLeaf = await registerDeposit(note1, tornadoTrees)
  //     let res = await tornadoTrees.getRegisteredDeposits()
  //     res.length.should.be.equal(1)
  //     // res[0].should.be.true
  //     await tornadoTrees.updateRoots([note1DepositLeaf], [])

  //     res = await tornadoTrees.getRegisteredDeposits()
  //     res.length.should.be.equal(0)

  //     await registerDeposit(note2, tornadoTrees)
  //     res = await tornadoTrees.getRegisteredDeposits()
  //     // res[0].should.be.true
  //   })
  // })

  afterEach(async () => {
    await revertSnapshot(snapshotId.result)
    // eslint-disable-next-line require-atomic-updates
    snapshotId = await takeSnapshot()
  })
})
