import { ERC721MockInstance } from './truffle-contracts/ERC721Mock'

type BaseContext = {
  instance: ERC721MockInstance
}

type NFTTokenContext = BaseContext & {
  tokenId: number
  saleAmountInWei: string | BN
}

declare module 'mocha' {
  export interface Context {
    context: NFTTokenContext
  }
}
