pragma solidity ^0.6.0;

import "./Wallet.sol";

contract MatchingEngine {
    
    using SafeMath for uint;
        
    struct Offer {
        uint amount;
        address user;
    }
    
    struct OrderList {
        uint nextPrice;
        
        mapping (uint => Offer) offers;
        uint firstOffer;
        uint numOfOffers;
    }
    
    struct OrderBook {
        mapping (uint => OrderList) buyOffers;
        uint maxBuyPrice;
        uint buyCount;
        
        mapping (uint => OrderList) sellOffers;
        uint minSellPrice;
        uint sellCount;
    }
    
    mapping (address => OrderBook) tokenBooks;
    
    Wallet user_wallet;
    
    constructor (address wallet) public {
        user_wallet = Wallet(wallet);
    }
    
    function buyOffer(address user, address token, uint price, uint amount) public {
        uint totalPrice = price.mul(amount);
        require(user_wallet.eth_balanceOf(user) >= totalPrice);
        OrderBook storage tokenOrder = tokenBooks[token];
        /*TODO: balance manipulation*/
        if (tokenOrder.buyCount == 0 || price <= tokenOrder.maxBuyPrice) {
            
        }
    }
    
    function storeBuyOrder (address user, address token, uint price, uint amount) public {
        OrderBook storage tokenOrder = tokenBooks[token];
        tokenOrder.buyCount.add(1);
        tokenOrder.buyOffers[price].offers[tokenOrder.buyCount] = Offer(amount, user);
    }
}
