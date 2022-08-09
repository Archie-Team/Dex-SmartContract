const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()


module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777"
    },
    bsctestnet: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    rinkeby: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://rinkeby.infura.io/v3/9497529ebd9b4ccfaabb477128cc6c22"),
      network_id: "*"
    },
    rinkeby_alc: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://eth-rinkeby.alchemyapi.io/v2/Cv8OX3aFDumXMbt37CsQVJRTWBfKnlBt"),
      network_id: "*"
      
    },
    rinkeby_tst: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://rpc.tenderly.co/fork/8c5c0de5-c5ac-4d63-9ce4-34f0f77d260f"),
      network_id: "*"
      
    },
    ethereum: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://mainnet.infura.io/v3/9497529ebd9b4ccfaabb477128cc6c22"),
      network_id: 1
    },
    ropsten: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://ropsten.infura.io/v3/49b2ce901eeb4d41bc972b31a4a7d1fb"),
      network_id: 3,
      networkCheckTimeoutnetworkCheckTimeout: 10000,
      timeoutBlocks: 200
      
    },
    ropsten_tst: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"),
      network_id: 3
      
    },
    mumbai: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, `https://polygon-mumbai.infura.io/v3/5743f6d173a141249a646aaf9ea45b54`),
      network_id: "*"
    },
    
  },

  compilers: {
    solc: {
      version: "^0.8.0",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    bscscan: process.env.BSCPRIVATE,
    etherscan: process.env.ETHERPRIVATE
  }
};