require('dotenv').config()
const HDWalletProvider = require('truffle-hdwallet-provider')
const utils = require('web3-utils')

module.exports = {
  // Uncommenting the defaults below
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  mocha: {
    enableTimeouts: false,
    networkCheckTimeout: 10000000,
  },
  networks: {
    // development: {
    //   host: '127.0.0.1',
    //   port: 8545,
    //   network_id: '*',
    // },
    //  test: {
    //    host: "127.0.0.1",
    //    port: 7545,
    //    network_id: "*"
    //  }
    kovan: {
      provider: () =>
        new HDWalletProvider(
          process.env.PRIVATE_KEY,
          'https://kovan.infura.io/v3/9b8f0ddb3e684ece890f594bf1710c88',
        ),
      network_id: 42,
      gas: 7000000,
      gasPrice: utils.toWei('10', 'gwei'),
      // confirmations: 0,
      // timeoutBlocks: 200,
      skipDryRun: true,
    },
    goerli: {
      provider: () =>
        new HDWalletProvider(
          process.env.PRIVATE_KEY,
          'https://goerli.infura.io/v3/da564f81919d40c9a3bcaee4ff44438d',
        ),
      network_id: 5,
      gas: 7000000,
      gasPrice: utils.toWei('10', 'gwei'),
      // confirmations: 0,
      // timeoutBlocks: 200,
      skipDryRun: true,
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          process.env.PRIVATE_KEY,
          'https://rinkeby.infura.io/v3/da564f81919d40c9a3bcaee4ff44438d',
        ),
      network_id: 4,
      gas: 7000000,
      gasPrice: utils.toWei('10', 'gwei'),
      // confirmations: 0,
      // timeoutBlocks: 200,
      skipDryRun: true,
    },
    coverage: {
      host: 'localhost',
      network_id: '*',
      port: 8554, // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01, // <-- Use this low gas price
    },
  },
  compilers: {
    solc: {
      version: '0.6.12',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
    external: {
      command: 'node ./compileHasher.js',
      targets: [
        {
          path: './build/contracts/Hasher2.json',
        },
        {
          path: './build/contracts/Hasher3.json',
        },
      ],
    },
  },
  plugins: ['truffle-plugin-verify', 'solidity-coverage'],
}
