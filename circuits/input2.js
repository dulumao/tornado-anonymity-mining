const fs = require('fs')
const jsSHA = require("jssha")
const { BN, toBN } = require('web3-utils')

const shaSnark = require('./witness.json')[1]
const snarkHash = toBN(shaSnark).toBuffer().toString('hex')
console.log('snark hash:  ', snarkHash)
