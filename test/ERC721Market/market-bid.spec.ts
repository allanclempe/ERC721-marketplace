import BN from 'bn.js'
import Web3 from 'web3'
import {
  assertEventOfType,
  assertEventsOfType,
  assertThrown,
  getTokenId,
} from '../helpers'
import { acceptBid, enterBid, mintNft, withdrawBid } from '../methods'
import { shouldHaveCorrectBalance } from './shared/market-balance'
import { shouldHaveCorrectOwner } from './shared/market-ownership'

const ERC721Mock = artifacts.require('ERC721Mock')

contract('ERC721 market bid', (accounts) => {
  const [bob, alice, carol] = accounts

  before(async function () {
    const instance = await ERC721Mock.deployed()
    const transaction = await mintNft(bob, 1, { instance })

    this.context = {
      instance,
      saleAmountInWei: Web3.utils.toWei('1'),
      tokenId: getTokenId(transaction),
    }
  })

  it(`should bid an nft`, async function () {
    const transaction = await enterBid(alice, this.context)

    assertEventOfType(transaction, 'ItemBidEntered', 0)
  })

  it(`should not accept the bid on owners behalf`, async function () {
    await assertThrown(
      () => acceptBid(carol, this.context),
      'allowed just for owner'
    )
  })

  it(`should accept an nft bid`, async function () {
    const transaction = await acceptBid(bob, this.context)

    assertEventsOfType(
      transaction,
      'Approval',
      'Transfer',
      'ItemNoLongerForSale',
      'ItemBought'
    )
  })

  shouldHaveCorrectBalance(bob)

  shouldHaveCorrectOwner(alice)

  it(`should not accept bid from its owners`, async function () {
    await assertThrown(
      () => enterBid(alice, this.context),
      'allowed just for non owner'
    )
  })

  it(`should withdraw a bid and make a refund`, async function () {
    const account = accounts[2]

    await enterBid(account, this.context)

    const prevBal = new BN(await web3.eth.getBalance(account))
    const transaction = await withdrawBid(account, this.context)
    const newBal = new BN(await web3.eth.getBalance(account))

    assertEventsOfType(transaction, 'ItemBidWithdrawn')

    // we could do the calculation here, deducting the gas fee for both operation to match the bid amount
    // but I will keep this way for now
    expect(newBal > prevBal).to.be.true
  })
})
