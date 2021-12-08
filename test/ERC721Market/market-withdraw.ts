import BN from 'bn.js'
import Web3 from 'web3'
import { assertEventsOfType, assertThrown, getTokenId } from '../helpers'
import { acceptBid, enterBid, mintNft, withdraw } from '../methods'

const ERC721Mock = artifacts.require('ERC721Mock')

contract('ERC721 market withdraw', (accounts) => {
  const [, alice, carol] = accounts

  before(async function () {
    const instance = await ERC721Mock.deployed()
    const transaction = await mintNft(alice, 1, { instance })

    this.context = {
      instance,
      saleAmountInWei: Web3.utils.toWei('1'),
      tokenId: getTokenId(transaction),
    }

    await enterBid(carol, this.context)
    await acceptBid(alice, this.context)
  })

  it(`should withdraw balance`, async function () {
    const account = alice // seller.

    const prevBalEth = new BN(await web3.eth.getBalance(account))
    const transaction = await withdraw(account, this.context)
    const newBalEth = new BN(await web3.eth.getBalance(account))

    assertEventsOfType(transaction, 'BalanceWithdrawn')

    expect(newBalEth.gt(prevBalEth)).to.be.true
  })

  it(`should not have balance after withdraw`, async function () {
    const { instance } = this.context

    const account = alice
    const balance = new BN(await instance.getWithdrawBalance(account))

    expect(balance.toNumber()).to.be.eq(0)
  })

  it(`should not have balance to withdraw`, async function () {
    const account = alice

    await assertThrown(
      () => withdraw(account, this.context),
      'you got no balance to withdraw'
    )
  })
})
