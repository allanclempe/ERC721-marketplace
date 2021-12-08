// SPDX-License-Identifier: MIT
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import './IERC721Market.sol';

pragma solidity ^0.8.9;

abstract contract ERC721Market is ERC721Enumerable, IERC721Market {
    using SafeMath for uint256;

    mapping(uint256 => Offer) public _itemsOfferedForSale;

    mapping(uint256 => Bid) public _itemBids;

    mapping(address => uint256) public _pendingWithdrawals;

    uint256 public constant INVERSE_BASIS_POINT = 10000;

    uint256 private _totalCut;

    modifier onlyOwnerOf(uint256 index) {
        require(ownerOf(index) == _msgSender(), 'allowed just for owner');
        _;
    }

    modifier onlyNotOwnerOf(uint256 index) {
        require(ownerOf(index) != _msgSender(), 'allowed just for non owner');
        _;
    }

    modifier onlyValidIndex(uint256 index) {
        require(index < totalSupply());
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

    event ItemBidEntered(
        uint256 indexed index,
        uint256 value,
        address indexed fromAddress
    );

    event ItemOffered(
        uint256 indexed index,
        uint256 minValue,
        address indexed toAddress
    );

    event ItemBought(
        uint256 indexed index,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );

    event ItemNoLongerForSale(uint256 indexed index);

    event ItemBidWithdrawn(
        uint256 indexed index,
        uint256 value,
        address indexed fromAddress
    );

    event BalanceWithdrawn(address from, uint256 value);

    constructor(uint256 totalCut_) {
        _totalCut = totalCut_;
    }

    function acceptBid(uint256 index, uint256 minPrice)
        public
        onlyOwnerOf(index)
        onlyValidIndex(index)
    {
        address seller = _msgSender();

        Bid storage bid = _itemBids[index];

        require(bid.value > 0);
        require(bid.value >= minPrice);

        transferFrom(seller, bid.bidder, index);

        _removeFromSale(index, bid.bidder);

        _addBalanceSeller(seller, bid.value);

        _itemBids[index] = Bid(false, index, address(0x0), 0);

        emit ItemBought(index, bid.value, seller, bid.bidder);
    }

    // Transfer ownership of an item to another user without requiring payment
    function transferItem(address to, uint256 index)
        public
        onlyOwnerOf(index)
        onlyValidIndex(index)
    {
        Offer storage itemOffer = _itemsOfferedForSale[index];
        address owner = _msgSender();

        if (itemOffer.isForSale) {
            _removeFromSale(index, itemOffer.seller);
        }

        transferFrom(owner, to, index);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        _refundBid(index, to);
    }

    function buyItem(uint256 index) public payable onlyValidIndex(index) {
        Offer storage offer = _itemsOfferedForSale[index];

        require(offer.isForSale, 'not for sale');

        address buyer = _msgSender();

        require(
            offer.onlySellTo == address(0x0) || offer.onlySellTo == buyer,
            'item must be sold to a specific buyer'
        );

        require(
            msg.value >= offer.minValue,
            'value must be greather than the offer'
        );

        require(ownerOf(index) == offer.seller, 'seller no longer owner');

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

    function withdraw() public payable {
        address sender = _msgSender();
        uint256 amount = _pendingWithdrawals[sender];

        require(amount > 0, 'you got no balance to withdraw');

        // clear balance to avoid re-entry
        _pendingWithdrawals[sender] = 0;

        payable(sender).transfer(amount);

        emit BalanceWithdrawn(sender, amount);
    }

    function withdrawBidForItem(uint256 index)
        public
        payable
        onlyNotOwnerOf(index)
        onlyValidIndex(index)
    {
        Bid storage bid = _itemBids[index];

        address sender = _msgSender();

        require(bid.bidder == sender, 'you are not the bidder');

        emit ItemBidWithdrawn(index, bid.value, sender);

        uint256 amount = bid.value;
        _itemBids[index] = Bid(false, index, address(0x0), 0);
        // Refund the bid money
        payable(sender).transfer(amount);
    }

    function getWithdrawBalance(address fromAddress)
        public
        view
        returns (uint256)
    {
        return _pendingWithdrawals[fromAddress];
    }

    function offerForSaleToAddress(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) public onlyOwnerOf(index) onlyValidIndex(index) {
        _offerForSale(index, minSalePriceInWei, toAddress);
    }

    function offerForSale(uint256 index, uint256 minSalePriceInWei)
        public
        onlyOwnerOf(index)
        onlyValidIndex(index)
    {
        _offerForSale(index, minSalePriceInWei, address(0x0));
    }

    function enterBid(uint256 index)
        public
        payable
        onlyNotOwnerOf(index)
        onlyValidIndex(index)
    {
        require(msg.value > 0);

        address buyer = _msgSender();

        Bid storage existing = _itemBids[index];

        require(msg.value > existing.value, 'bid needs to be higher');

        if (existing.value > 0) {
            // Refund the failing bid
            _addBalance(existing.bidder, existing.value);
        }

        _itemBids[index] = Bid(true, index, buyer, msg.value);

        emit ItemBidEntered(index, msg.value, buyer);
    }

    function itemNoLongerForSale(uint256 index) public onlyOwnerOf(index) {
        _removeFromSale(index, _msgSender());
    }

    function calculateCut(uint256 amount)
        internal
        virtual
        returns (MarketCut[] memory)
    {
        MarketCut[] memory lockedInContract = new MarketCut[](1);
        lockedInContract[0] = MarketCut(
            address(this),
            computeCut(amount, _totalCut)
        );
        return lockedInContract;
    }

    function computeCut(uint256 price, uint256 cut)
        internal
        pure
        returns (uint256)
    {
        return (price.mul(cut)).div(INVERSE_BASIS_POINT);
    }

    function _addBalanceActioneers(uint256 amount) private returns (uint256) {
        uint256 totalAmount = 0;

        MarketCut[] memory procotolFees = calculateCut(amount);

        for (uint256 i = 0; i < procotolFees.length; i++) {
            _addBalance(procotolFees[i].to, procotolFees[i].amount);

            totalAmount = totalAmount.add(procotolFees[i].amount);
        }

        return totalAmount;
    }

    function _addBalanceSeller(address seller, uint256 amount) private {
        uint256 auctioneerCut = _addBalanceActioneers(amount);
        uint256 maxCut = computeCut(amount, _totalCut);

        require(
            auctioneerCut <= maxCut,
            'auctionner cut exceeded total defined'
        );

        _addBalance(seller, amount.sub(auctioneerCut));
    }

    function _addBalance(address to, uint256 amount) private {
        uint256 currentAmount = _pendingWithdrawals[to];
        _pendingWithdrawals[to] = currentAmount.add(amount);
    }

    function _offerForSale(
        uint256 index,
        uint256 minSalePriceInWei,
        address toAddress
    ) internal {
        address seller = _msgSender();

        _itemsOfferedForSale[index] = Offer(
            true,
            index,
            seller,
            minSalePriceInWei,
            toAddress
        );

        emit ItemOffered(index, minSalePriceInWei, toAddress);
    }

    function _removeFromSale(uint256 index, address seller) internal {
        _itemsOfferedForSale[index] = Offer(
            false,
            index,
            seller,
            0,
            address(0x0)
        );

        emit ItemNoLongerForSale(index);
    }

    function _refundBid(uint256 index, address to) internal {
        Bid storage bid = _itemBids[index];
        if (bid.bidder == to) {
            // Kill bid and refund value
            _addBalance(to, bid.value);
            _itemBids[index] = Bid(false, index, address(0x0), 0);
        }
    }
}
