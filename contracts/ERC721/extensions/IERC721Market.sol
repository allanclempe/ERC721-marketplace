// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

pragma solidity ^0.8.9;

interface IERC721Market is IERC721Enumerable {
    /// @dev transfer ownership of an item to another account without payment
    /// @param to new owner address
    /// @param index tokenId
    function transferItem(address to, uint256 index) external;

    /// @dev offer an item for sale. allowed just for owners.
    /// @param index tokenId
    /// @param minSalePriceInWei sale price in Wei
    function offerForSale(uint256 index, uint256 minSalePriceInWei) external;

    /// @dev offer an item for sale to an specific address. allowed just for owners.
    /// @param index tokenId
    /// @param minSalePriceInWei sale price in Wei
    /// @param toAddress buyer account
    function offerForSaleToAddress(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    /// @dev buy item offered for sale. transaction amount needs to match the offer
    /// @param index tokenId
    function buyItem(uint256 index) external payable;

    /// @dev remove item from sale. allowed just for owners.
    /// @param index tokenId
    function itemNoLongerForSale(uint256 index) external;

    /// @dev enter a new bid for an item. Transaction amount is locked in contract until seller accepts the bid.
    /// @param index tokenId
    function enterBid(uint256 index) external payable;

    /// @dev accepts entered bid
    /// @param index tokenId
    /// @param minPrice in wei, needs to be gt than bid price.
    function acceptBid(uint256 index, uint256 minPrice) external;

    /// @dev withdraw bid. the bid amount will be available for withdraw.
    /// @param index tokenId
    function withdrawBidForItem(uint256 index) external payable;

    /// @dev withdraw balance
    function withdraw() external payable;

    /// @dev check locked balance for a specific address
    /// @param fromAddress account
    function getWithdrawBalance(address fromAddress) external view returns (uint256);
}
