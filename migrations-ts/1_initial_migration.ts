import BN from 'bn.js'

const ERC721Mock = artifacts.require('ERC721Mock')

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(
    ERC721Mock,
    'ERC721Mock',
    'NFTE',
    'http://ipfs.com/id',
    new BN(process.env.CUT_AMOUNT)
  )
} as Truffle.Migration

// because of https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {}
