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
        uint prevPrice;
        
        mapping (uint => Offer) offers;
        uint firstOffer;
        uint numOfOffers;
    }
    
    struct OrderBook {
        mapping (uint => OrderList) buyOffers;
        uint maxBuyPrice;
        uint minBuyPrice;
        uint buyCount;
        
        mapping (uint => OrderList) sellOffers;
        uint minSellPrice;
        uint maxSellPrice;
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
        user_wallet.sub_eth(user, totalPrice);
        if (tokenOrder.buyCount == 0 || price <= tokenOrder.maxBuyPrice) { //create new order if we have nothing to process
            storeBuyOrder(user, token, price, amount);
        } else { //instanly execute order if it is possible
            uint ethAmount = 0;
            uint remain = amount;
            uint buyPrice = tokenOrder.minSellPrice;
            uint offCounter;
            while (buyPrice <= price && remain > 0) { //order execution loop
                offCounter = tokenOrder.sellOffers[buyPrice].firstOffer;
            }
        }
    }
    
    function storeBuyOrder (address user, address token, uint price, uint amount) public {
        OrderBook storage tokenOrder = tokenBooks[token];
        tokenOrder.buyOffers[price].numOfOffers = tokenOrder.buyOffers[price].numOfOffers.add(1);
        tokenOrder.buyOffers[price].offers[tokenOrder.buyCount] = Offer(amount, user);
        if (tokenOrder.buyOffers[price].numOfOffers == 1) {
            tokenOrder.buyOffers[price].firstOffer = 1;
            tokenOrder.buyCount = tokenOrder.buyCount.add(1);
            uint currPrice = tokenOrder.maxBuyPrice;
            uint minPrice = tokenOrder.minBuyPrice;
            
            if (minPrice == 0 || minPrice > price) {
                if (currPrice == 0 ) {
                    tokenOrder.maxBuyPrice = price;
                    tokenOrder.buyOffers[price].nextPrice = price;
                    tokenOrder.buyOffers[price].prevPrice = 0;
                } else {
                    tokenOrder.buyOffers[minPrice].prevPrice = price;
                    tokenOrder.buyOffers[price].nextPrice = minPrice;
                    tokenOrder.buyOffers[price].prevPrice = 0;
                }
                tokenOrder.minBuyPrice = price;
            } else if (currPrice < price) {
                tokenOrder.buyOffers[currPrice].nextPrice = price;
                tokenOrder.buyOffers[price].nextPrice = price;
                tokenOrder.buyOffers[price].prevPrice = currPrice;
                tokenOrder.maxBuyPrice = price;
            } else {
                uint buyPrice = tokenOrder.maxBuyPrice;
                bool done = false;
                while (buyPrice > 0 && !done) {
                    if (buyPrice < price && price < tokenOrder.buyOffers[buyPrice].nextPrice) {
                        tokenOrder.buyOffers[price].prevPrice = buyPrice;
                        tokenOrder.buyOffers[price].nextPrice = tokenOrder.buyOffers[buyPrice].nextPrice;
                        tokenOrder.buyOffers[tokenOrder.buyOffers[buyPrice].nextPrice].prevPrice = price;
                        tokenOrder.buyOffers[buyPrice].nextPrice = price;
                        done = true;
                    }
                    buyPrice = tokenOrder.buyOffers[buyPrice].prevPrice;
                }
            }
        }
    }
}
