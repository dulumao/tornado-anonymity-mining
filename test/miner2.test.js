/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()

const { takeSnapshot, revertSnapshot } = require('../scripts/ganacheHelper')
const Test = artifacts.require('Test')

contract.only('Miner', () => {
  let contract
  let snapshotId

  before(async () => {
    contract = await Test.new()
    snapshotId = await takeSnapshot()
  })

  describe('#constructor', () => {
    it('should work', async () => {
      await contract.test1()
    })
  })

  afterEach(async () => {
    await revertSnapshot(snapshotId.result)
    // eslint-disable-next-line require-atomic-updates
    snapshotId = await takeSnapshot()
  })
})
