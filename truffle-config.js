var HDWalletProvider = require('@truffle/hdwallet-provider');
const {
  MNEMONIC,
  ETHERSCAN,
  BSCSCAN,
  MAINNET_ETHEREUM_NODE,
  TESTNET_ETHEREUM_NODE,
  MAINNET_BSC_NODE,
  TESTNET_BSC_NODE,
} = require('./config/config.json');

module.exports = {
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    etherscan: ETHERSCAN,
    bscscan: BSCSCAN,
  },
  networks: {
    development: {
      host: 'localhost',
      port: 7545,
      network_id: '*', // Match any network id,
      gasPrice: 1000000000, // 8 Gwei
    },
    ethereum_mainnet: {
      provider: () => new HDWalletProvider(MNEMONIC, MAINNET_ETHEREUM_NODE),
      network_id: '1',
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 50000,
      skipDryRun: true,
      networkCheckTimeout: 999999,
      websocket: true,
    },
    kovan: {
      provider: () => new HDWalletProvider(MNEMONIC, TESTNET_ETHEREUM_NODE),
      network_id: 42,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 50000,
      skipDryRun: true,
      networkCheckTimeout: 999999,
      websocket: true,
    },
    binance_test: {
      provider: () => new HDWalletProvider(MNEMONIC, TESTNET_BSC_NODE),
      network_id: '97',
      confirmations: 1,
      skipDryRun: true,
      networkCheckTimeout: 999999,
      timeoutBlocks: 50000,
      websocket: true,
    },
    binance_mainnet: {
      provider: () => new HDWalletProvider(MNEMONIC, MAINNET_BSC_NODE),
      network_id: '56',
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 50000,
      skipDryRun: true,
      networkCheckTimeout: 999999,
      websocket: true,
    },
  },
  compilers: {
    solc: {
      version: '^0.8.1',
      settings: {
        optimizer: {
          enabled: false,
          runs: 200,
        },
      },
    },
  },
  mocha: {
    enableTimeouts: false,
  },
};
