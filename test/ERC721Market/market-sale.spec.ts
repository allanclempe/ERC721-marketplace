import BN from 'bn.js'
import Web3 from 'web3'
import { assertEventsOfType, getTokenId } from '../helpers'
import { buyNft, enterBid, mintNft, offerNft } from '../methods'

import { shouldHaveCorrectBalance } from './shared/market-balance'
import { shouldHaveCorrectOwner } from './shared/market-ownership'

const ERC721Mock = artifacts.require('ERC721Mock')

contract('ERC721 market sale', (accounts) => {
  const [bob, alice, carol] = accounts

  before(async function () {
    const instance = await ERC721Mock.deployed()
    const transaction = await mintNft(bob, 1, { instance })

    this.context = {
      instance,
      tokenId: getTokenId(transaction),
      saleAmountInWei: Web3.utils.toWei('1'),
    }
  })

  it(`should offer nft for sale`, async function () {
    const transaction = await offerNft(bob, this.context)

    assertEventsOfType(transaction, 'ItemOffered')
  })

  it(`should buy offered nft for sale`, async function () {
    const transaction = await buyNft(alice, this.context)

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

  describe('buy nft with bid', () => {
    before(async function () {
      await offerNft(alice, this.context)
    })

    it('it should refund the bid after bought', async function () {
      const { instance, saleAmountInWei } = this.context
      const salePrice = new BN(saleAmountInWei)

      await enterBid(carol, this.context) // this bid should be refunded.
      await buyNft(carol, this.context)

      const newBal = new BN(await instance.getWithdrawBalance(carol))

      // should refund the the bid when transfered without
      expect(newBal.sub(salePrice).toNumber()).to.be.eq(0)
    })
  })
})
