## Solidity contract marketplace extension for ERC721 (NFTs)

**Bid and ask mechanism** to buy and sell NFTs token.

## Install

```bash
$ npm i erc721-marketplace --save
```

## Getting started

Extend your contact with `ERC721Maket.sol`. Constructor receives the platform `cut` represented by points between 0-1000 where 100 is 1%, 1000 is 10% and 10000 is 100%.

```solidity
import "erc721-marketplace/ERC721/extensions/ERC721Market.sol";

contract NFTContract is ERC721Market {
  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    uint256 cut
  ) ERC721(name, symbol) ERC721Market(cut) {}
}

```

## Buy or sell a NFT

There are 3 ways of transfering ownership of a token. **Offering for sale**, **bidding** it or a simple **transfer of ownership** without any payment.

Check [IERC721Market.sol](contracts/ERC721/extensions/IERC721Market.sol) interface for more information.

## Platform cut

By default, the cut will be locked in the contract address, but you can override `_calculateCut` function to customise with your own share distribution.

```solidity
function calculateCut(uint256 amount, uint256 cut)
  internal
  pure
  override
  returns (MarketCut[] memory)
{
  MarketCut[] memory fees = new MarketCut[](2);

  // primary benefitiary

  fees[0] = MarketCut(
    address(0xD51cf74a5CD2029CDF0d107D5239FcCdfFeC2008),
    computeCut(amount, 150) // 1.5%
  );

  // secondary

  fees[1] = MarketCut(
    address(0x021cFEEe4a9F5336D14C5173d811aB8fE3829B77),
    computeCut(amount, 100) // 1%
  );

  return fees;
}

```

- Every confirmed sale will call this function if cut amount is greather than 0.

## What in here so far

- Built on top of [ERC721](https://docs.openzeppelin.com/contracts/4.x/erc721) [openzeppelin contract](https://github.com/OpenZeppelin/openzeppelin-contracts)
- Based on [CryptoPunk](https://github.com/larvalabs/cryptopunks) marketplace contract
- Using [TypeChain](https://github.com/dethcrypto/TypeChain) to generate types from solidity contracts
