const fs = require('fs')
const jsSHA = require("jssha")
const { BN, toBN } = require('web3-utils')

const input = "0x19e333499855692e089a21c8c0962ee82bc72a2953305df4748ff3f71ea09f0d"
const bytes = toBN(input).toBuffer('be')
console.log('input:     ', bytes.toString('hex'))

const shaObj = new jsSHA("SHA-256", "ARRAYBUFFER", {  })
shaObj.update(bytes)
const hash = shaObj.getHash("HEX")
console.log('js hash:   ', hash)

const shaSnark = require('./witness.json')[1]
const snarkHash = toBN(shaSnark).toBuffer().toString('hex')
console.log('snark hash:', snarkHash)
