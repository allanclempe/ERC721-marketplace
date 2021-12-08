import Web3 from 'web3'
import { BaseContext, NFTTokenContext } from '../types/mocha'

export async function mintNft(
  from: string,
  qty: number,
  context: BaseContext,
  price = Web3.utils.toWei('0.5')
) {
  const { instance } = context

  return instance.mintItem(qty, {
    value: price,
    from,
  })
}

export async function enterBid(from: string, context: NFTTokenContext) {
  const { tokenId, instance, saleAmountInWei } = context

  return instance.enterBid(tokenId, {
    value: saleAmountInWei,
    from,
  })
}

export async function withdraw(from: string, context: BaseContext) {
  const { instance } = context

  return instance.withdraw({
    from,
  })
}

export async function acceptBid(from: string, context: NFTTokenContext) {
  const { tokenId, instance, saleAmountInWei } = context

  return instance.acceptBid(tokenId, saleAmountInWei, {
    from: from,
  })
}

export async function withdrawBid(from: string, context: NFTTokenContext) {
  const { tokenId, instance } = context

  return instance.withdrawBidForItem(tokenId, {
    from,
  })
}

export async function offerNft(from: string, context: NFTTokenContext) {
  const { tokenId, instance, saleAmountInWei } = context

  return instance.offerForSale(tokenId, saleAmountInWei, {
    from,
  })
}

export async function buyNft(from: string, context: NFTTokenContext) {
  const { tokenId, instance, saleAmountInWei } = context

  return instance.buyItem(tokenId, {
    value: saleAmountInWei,
    from,
  })
}

export async function transferNft(
  from: string,
  to: string,
  context: NFTTokenContext
) {
  const { instance, tokenId } = context

  return instance.transferItem(to, tokenId, {
    from,
  })
}
