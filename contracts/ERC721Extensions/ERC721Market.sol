// SPDX-License-Identifier: MIT
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IERC721Market.sol";

pragma solidity ^0.8.9;

abstract contract ERC721Market is ERC721Enumerable, IERC721Market {
    using SafeMath for uint256;

    mapping(uint256 => Offer) public itemsOfferedForSale;

    mapping(uint256 => Bid) public itemBids;

    mapping(address => uint256) public pendingWithdrawals;

    uint256 public constant INVERSE_BASIS_POINT = 10000;

    uint256 private _totalCut;

    modifier onlyOwnerOf(uint256 index) {
        require(ownerOf(index) == _msgSender(), "allowed just for owner");
        _;
    }

    modifier onlyNotOwnerOf(uint256 index) {
        require(ownerOf(index) != _msgSender(), "allowed just for non owner");
        _;
    }

    modifier onlyValidIndex(uint256 index) {
        require(_exists(index), "token not minted");
        _;
    }

    struct Offer {
        bool isForSale;
        uint256 nftIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 nftIndex;
        address bidder;
        uint256 value;
    }

    struct MarketCut {
        address to;
        uint256 amount;
    }

    event ItemBidEntered(uint256 indexed index, uint256 value, address indexed fromAddress);

    event ItemOffered(uint256 indexed index, uint256 minValue, address indexed toAddress);

    event ItemBought(uint256 indexed index, uint256 value, address indexed fromAddress, address indexed toAddress);

    event ItemNoLongerForSale(uint256 indexed index);

    event ItemBidWithdrawn(uint256 indexed index, uint256 value, address indexed fromAddress);

    event BalanceWithdrawn(address from, uint256 value);

    constructor(uint256 totalCut_) {
        _totalCut = totalCut_;
    }

    /// @dev See {IERC721Market-transferItem}.
    function transferItem(address to, uint256 index) public onlyOwnerOf(index) onlyValidIndex(index) {
        Offer storage itemOffer = itemsOfferedForSale[index];
        address owner = _msgSender();

        if (itemOffer.isForSale) {
            _removeFromSale(index, itemOffer.seller);
        }

        transferFrom(owner, to, index);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        _refundBid(index, to);
    }

    /// @dev See {IERC721Market-offerForSale}.
    function offerForSale(uint256 index, uint256 minSalePriceInWei) public onlyOwnerOf(index) onlyValidIndex(index) {
        _offerForSale(index, minSalePriceInWei, address(0x0));
    }

    /// @dev See {IERC721Market-offerForSaleToAddress}.
    function offerForSaleToAddress(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) public onlyOwnerOf(index) onlyValidIndex(index) {
        _offerForSale(index, minSalePriceInWei, toAddress);
    }

    /// @dev See {IERC721Market-buyItem}.
    function buyItem(uint256 index) public payable onlyValidIndex(index) {
        Offer storage offer = itemsOfferedForSale[index];

        require(offer.isForSale, "not for sale");

        address buyer = _msgSender();

        require(offer.onlySellTo == address(0x0) || offer.onlySellTo == buyer, "addressed to a specifc buyer");

        require(msg.value >= offer.minValue, "transaction is lower than offer");

        require(ownerOf(index) == offer.seller, "seller no longer owner");

        address seller = offer.seller;

        // we can safely transfer here, ownership already verified.
        _transfer(seller, buyer, index);

        _removeFromSale(index, seller);

        _addBalanceSeller(seller, msg.value);

        emit ItemBought(index, msg.value, seller, buyer);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        _refundBid(index, buyer);
    }

    /// @dev See {IERC721Market-itemNoLongerForSale}.
    function itemNoLongerForSale(uint256 index) public onlyOwnerOf(index) {
        _removeFromSale(index, _msgSender());
    }

    /// @dev See {IERC721Market-enterBid}.
    function enterBid(uint256 index) public payable onlyNotOwnerOf(index) onlyValidIndex(index) {
        require(msg.value > 0, "transaction has not value");

        address buyer = _msgSender();

        Bid storage existing = itemBids[index];

        require(msg.value > existing.value, "bid needs to be higher");

        if (existing.value > 0) {
            // Refund the failing bid
            _addBalance(existing.bidder, existing.value);
        }

        itemBids[index] = Bid(true, index, buyer, msg.value);

        emit ItemBidEntered(index, msg.value, buyer);
    }

    /// @dev See {IERC721Market-acceptBid}.
    function acceptBid(uint256 index, uint256 minPrice) public onlyOwnerOf(index) onlyValidIndex(index) {
        address seller = _msgSender();

        Bid storage bid = itemBids[index];

        require(bid.value > 0, "bid cannot be 0");
        require(bid.value >= minPrice, "minPrice is lower than bid");

        transferFrom(seller, bid.bidder, index);

        _removeFromSale(index, bid.bidder);

        _addBalanceSeller(seller, bid.value);

        itemBids[index] = Bid(false, index, address(0x0), 0);

        emit ItemBought(index, bid.value, seller, bid.bidder);
    }

    /// @dev See {IERC721Market-withdrawBidForItem}.
    function withdrawBidForItem(uint256 index) public payable onlyNotOwnerOf(index) onlyValidIndex(index) {
        Bid storage bid = itemBids[index];

        address sender = _msgSender();

        require(bid.bidder == sender, "you are not the bidder");

        emit ItemBidWithdrawn(index, bid.value, sender);

        uint256 amount = bid.value;
        itemBids[index] = Bid(false, index, address(0x0), 0);
        // Refund the bid money
        payable(sender).transfer(amount);
    }

   /// @dev See {IERC721Market-withdraw}.
    function withdraw() public payable {
        address sender = _msgSender();
        uint256 amount = pendingWithdrawals[sender];

        require(amount > 0, "you got no balance to withdraw");

        // clear balance to avoid re-entry
        pendingWithdrawals[sender] = 0;

        payable(sender).transfer(amount);

        emit BalanceWithdrawn(sender, amount);
    }

    /// @dev See {IERC721Market-getWithdrawBalance}.
    function getWithdrawBalance(address fromAddress) public view returns (uint256) {
        return pendingWithdrawals[fromAddress];
    }

    /// @dev offer item for sale
    /// @param index tokenId
    /// @param minSalePriceInWei sale price
    /// @param toAddress buyer account, if address(0) is public
    function _offerForSale(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) internal {
        address seller = _msgSender();

        itemsOfferedForSale[index] = Offer(true, index, seller, minSalePriceInWei, toAddress);

        emit ItemOffered(index, minSalePriceInWei, toAddress);
    }

    /// @dev calculate cut for the platform. could be shared between many accounts and different percentages
    /// default behaviour is to locked _totalCut in the contract address
    /// core contract can override and write the default logic
    /// @param amount sale amount
    function _calculateCut(uint256 amount) internal virtual returns (MarketCut[] memory) {
        MarketCut[] memory lockedInContract = new MarketCut[](1);
        lockedInContract[0] = MarketCut(address(this), _computeCut(amount, _totalCut));
        return lockedInContract;
    }

    /// @dev calc de cut percentage
    /// @param price sale price
    /// @param cut 0-10000
    function _computeCut(uint256 price, uint256 cut) internal pure returns (uint256) {
        return (price.mul(cut)).div(INVERSE_BASIS_POINT);
    }

    /// @dev calcute cut and add balance to the correct address
    /// @param amount sale price
    /// @return seller proceeds
    function _addBalanceActioneers(uint256 amount) private returns (uint256) {
        uint256 totalAmount = 0;

        MarketCut[] memory procotolFees = _calculateCut(amount);

        for (uint256 i = 0; i < procotolFees.length; i++) {
            _addBalance(procotolFees[i].to, procotolFees[i].amount);

            totalAmount = totalAmount.add(procotolFees[i].amount);
        }

        return totalAmount;
    }

    /// @dev add balance to the seller after computed cut
    /// @param seller seller address
    /// @param amount sale amount
    function _addBalanceSeller(address seller, uint256 amount) private {
        uint256 auctioneerCut = _addBalanceActioneers(amount);
        uint256 maxCut = _computeCut(amount, _totalCut);

        require(auctioneerCut <= maxCut, "auctionner cut exceeded");

        _addBalance(seller, amount.sub(auctioneerCut));
    }

    /// @dev add balance to a specific account
    /// @param to account
    /// @param amount total amount
    function _addBalance(address to, uint256 amount) private {
        uint256 currentAmount = pendingWithdrawals[to];
        pendingWithdrawals[to] = currentAmount.add(amount);
    }

    /// @dev remove item from sale
    /// @param index tokenId
    /// @param seller seller account
    function _removeFromSale(uint256 index, address seller) internal {
        itemsOfferedForSale[index] = Offer(false, index, seller, 0, address(0x0));

        emit ItemNoLongerForSale(index);
    }

    /// @dev make a refund for an existent bid. will be available for withdraw
    /// @param index tokenId
    /// @param to refund to
    function _refundBid(uint256 index, address to) internal {
        Bid storage bid = itemBids[index];
        if (bid.bidder == to) {
            // Kill bid and refund value
            _addBalance(to, bid.value);
            itemBids[index] = Bid(false, index, address(0x0), 0);
        }
    }
}
