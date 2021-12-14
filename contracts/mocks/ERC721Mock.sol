// SPDX-License-Identifier: MIT
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../ERC721Market.sol";

pragma solidity ^0.8.9;

contract ERC721Mock is ERC721Market {
    uint256 public constant MAX_SUPPLY = 5000;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 totalCut
    ) ERC721(name, symbol) ERC721Market(totalCut) {}

    /// @dev example to mint one or many NFTS.
    function mintItem(uint256 qty) public payable {
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
        require(qty > 0, "You cannot mint 0 Cars.");
        require(qty <= 20, "You may not buy more than 20 NFTs at once");
        require(
            SafeMath.add(totalSupply(), qty) <= MAX_SUPPLY,
            "Exceeds maximum supply."
        );

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    /// @dev override and implement your own logic to share the cut.
    /* 
    function calculateCut(uint256 amount)
        internal
        pure
        override
        returns (MarketCut[] memory)
    {
        MarketCut[] memory fees = new MarketCut[](1);
        fees[0] = MarketCut(
            address(0x7205E22cA218B46D72CdF8C17bB071E5836A763E),
            computeCut(amount, 251)
        );

        // add more addresses here and return all.

        return fees;
    }
    */
}
