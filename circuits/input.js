const fs = require('fs')
const jsSHA = require("jssha")
const { BN, toBN } = require('web3-utils')

const input = "0x13f47d13ee2fe6c845b2ee141af81de858df4ec549a58b7970bb96645bc8d2"
const bytes = toBN(input).toBuffer('be', 31)
console.log('input:     ', bytes.toString('hex'))

const shaObj = new jsSHA("SHA-256", "ARRAYBUFFER", {  })
shaObj.update(bytes)
const hash = shaObj.getHash("HEX")
console.log('js hash:   ', hash)

const shaSnark = require('./witness.json')[1]
const snarkHash = toBN(shaSnark).toBuffer().toString('hex')
console.log('snark hash:  ', snarkHash)
