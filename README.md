## Marketplace contract for non-fungible tokens (NFTs)

**Bid and ask mechanism** to buy and sell NFTs token.

- Built on top of [ERC721](https://docs.openzeppelin.com/contracts/4.x/erc721) [openzeppelin contract](https://github.com/OpenZeppelin/openzeppelin-contracts)
- Based on [CryptoPunk](https://github.com/larvalabs/cryptopunks) marketplace contract
- Using [TypeChain](https://github.com/dethcrypto/TypeChain) to generate types from solidity contracts

### Installation

```console
$ npm i -g solc ganache-cli truffle
$ npm i
```

### Run ganache emulator

```console
$ npm run ganache
```

### Run contract migration

```console
$ npm run migrate
```

### Run unit tests

```console
$ npm run test
```

## Try yourself (implementation)

Extend your contact with `ERC721Maket` where `totalCut` is the maximum cut fee allowed, represented by points of 0-1000 where 100 is 1%

```solidity
import "./ERC721Market.sol";

contract NFTContract is ERC721Market {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 totalCut
    ) 
    ERC721(name, symbol) 
    ERC721Market(totalCut) 
    {}
}
```

By default, the cut will be locked in the contract address, but you can override `calculateCut` function and write your own logic.

```solidity
 function calculateCut(uint256 amount)
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

Every confirmed sale in your contract will call this function and lock the correct amount for each account. 

*node: `totalCut` must match the summarised points between all participants - for instance totalCut=250 (2.5%)*

### Public contract methods available

Checkout [IERC721Market.sol](contracts/IERC721Market.sol) interface