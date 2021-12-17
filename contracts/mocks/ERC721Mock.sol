// SPDX-License-Identifier: MIT
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../ERC721Market.sol';

pragma solidity ^0.8.9;

contract ERC721Mock is ERC721Market {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5000;

    string internal metaBaseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 totalCut
    ) ERC721(name_, symbol_) ERC721Market(totalCut) {
        metaBaseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metaBaseURI;
    }

    /// @dev example to mint one or many NFTS.
    function mintItem(uint256 qty) public payable {
        require(totalSupply() < MAX_SUPPLY, 'Sale has already ended.');
        require(qty > 0, 'You cannot mint 0 Cars.');
        require(qty <= 20, 'You may not buy more than 20 NFTs at once');
        require(
            SafeMath.add(totalSupply(), qty) <= MAX_SUPPLY,
            'Exceeds maximum supply.'
        );

        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json'))
                : '';
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
