// SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

pragma solidity ^0.8.9;

interface IERC721Market is IERC721Enumerable {
    function acceptBid(uint256 index, uint256 minPrice) external;

    function transferItem(address to, uint256 index) external;

    function buyItem(uint256 index) external payable;

    function withdraw() external payable;

    function withdrawBidForItem(uint256 index) external payable;

    function getWithdrawBalance(address fromAddress)
        external
        view
        returns (uint256);

    function offerForSaleToAddress(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function offerForSale(uint256 index, uint256 minSalePriceInWei) external;

    function enterBid(uint256 index) external payable;

    function itemNoLongerForSale(uint256 index) external;
}
