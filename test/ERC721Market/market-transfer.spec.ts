import BN from 'bn.js'
import Web3 from 'web3'
import { assertEventsOfType, assertThrown, getTokenId } from '../helpers'
import { enterBid, mintNft, offerNft, transferNft } from '../methods'

const ERC721Mock = artifacts.require('ERC721Mock')

contract('ERC721 transfer', (accounts) => {
  const [bob, alice, carol] = accounts

  before(async function () {
    const instance = await ERC721Mock.deployed()
    const price = Web3.utils.toWei('1')

    const transaction = await mintNft(bob, 1, { instance })
    const tokenId = getTokenId(transaction)

    this.context = {
      instance,
      tokenId,
      saleAmountInWei: price,
    }
  })

  it('should not accept transfer on owners behalf', async function () {
    const { instance, tokenId } = this.context
    const transferTo = alice

    await assertThrown(
      () =>
        instance.transferItem(transferTo, tokenId, {
          from: accounts[2],
        }),
      'allowed just for owner'
    )
  })

  it('should transfer token correctly', async function () {
    const { instance } = this.context

    const transferTo = alice
    const transaction = await transferNft(bob, transferTo, this.context)
    const newOwner = await instance.ownerOf(0)

    assertEventsOfType(transaction, 'Approval', 'Transfer')

    expect(newOwner).to.be.eq(transferTo)
  })

  it('it should remove from sale after transfered', async function () {
    await offerNft(alice, this.context)

    const transferTo = bob // back to the first owner
    const transaction = await transferNft(alice, transferTo, this.context)

    assertEventsOfType(
      transaction,
      'ItemNoLongerForSale', // should trigger this
      'Approval',
      'Transfer'
    )
  })

  describe('transfer nft with bid', () => {
    it('it should refund the bid after transfered', async function () {
      const { instance, saleAmountInWei } = this.context
      const salePrice = new BN(saleAmountInWei)

      const transferTo = carol

      await enterBid(transferTo, this.context) // this bid should be refunded.
      await transferNft(bob, transferTo, this.context)

      const newBal = new BN(await instance.getWithdrawBalance(transferTo))

      // should refund the the bid when transfered without
      expect(newBal.sub(salePrice).toNumber()).to.be.eq(0)
    })
  })
})
