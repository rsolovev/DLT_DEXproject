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
        //user_wallet.sub_eth(user, totalPrice);
        if (tokenOrder.sellCount == 0 || price < tokenOrder.minSellPrice) { //create new order if we have nothing to process
            storeBuyOrder(user, token, price, amount);
        } else { //instanly execute order if it is possible
            uint ethAmount = 0;
            uint remain = amount;
            uint buyPrice = tokenOrder.minSellPrice;
            uint offCounter;
            while (buyPrice <= price && remain > 0) { //order execution loop
                offCounter = tokenOrder.sellOffers[buyPrice].firstOffer;
                while (offCounter <= tokenOrder.sellOffers[buyPrice].numOfOffers && remain > 0) {
                    uint currAmount = tokenOrder.sellOffers[buyPrice].offers[offCounter].amount;
                    if (currAmount <= remain) {
                        ethAmount = currAmount * buyPrice;
                        user_wallet.send_eth(user, tokenOrder.sellOffers[buyPrice].offers[offCounter].user, ethAmount);
                        user_wallet.send_token(tokenOrder.sellOffers[buyPrice].offers[offCounter].user, user, token, currAmount);
                        tokenOrder.sellOffers[buyPrice].offers[offCounter].amount = 0;
                        tokenOrder.sellOffers[buyPrice].firstOffer = tokenOrder.sellOffers[buyPrice].firstOffer.add(1);
                        remain = remain.sub(currAmount);
                    } else {
                        require(tokenOrder.sellOffers[buyPrice].offers[offCounter].amount >= remain);
                        ethAmount = remain * buyPrice;
                        user_wallet.send_eth(user, tokenOrder.sellOffers[buyPrice].offers[offCounter].user, ethAmount);
                        user_wallet.send_token(tokenOrder.sellOffers[buyPrice].offers[offCounter].user, user, token, remain);
                        tokenOrder.sellOffers[buyPrice].offers[offCounter].amount = tokenOrder.sellOffers[buyPrice].offers[offCounter].amount.sub(remain);
                        remain = 0;
                    }
                    if (offCounter == tokenOrder.sellOffers[buyPrice].numOfOffers && tokenOrder.sellOffers[buyPrice].offers[offCounter].amount == 0) {
                        tokenOrder.sellCount = tokenOrder.sellCount.sub(1);
                        if (buyPrice == tokenOrder.sellOffers[buyPrice].nextPrice || tokenOrder.sellOffers[buyPrice].nextPrice == 0) {
                            tokenOrder.minSellPrice = 0;
                        } else {
                            tokenOrder.minSellPrice = tokenOrder.sellOffers[buyPrice].nextPrice;
                            tokenOrder.sellOffers[tokenOrder.sellOffers[buyPrice].nextPrice].prevPrice = 0;
                        }
                    }
                    offCounter = offCounter.add(1);
                }
                buyPrice = tokenOrder.minSellPrice;
            }
            if (remain > 0) {
                buyOffer(user, token, price, remain);
            }
        }
    }
    
    function storeBuyOrder (address user, address token, uint price, uint amount) public {
        OrderBook storage tokenOrder = tokenBooks[token];
        tokenOrder.buyOffers[price].numOfOffers = tokenOrder.buyOffers[price].numOfOffers.add(1);
        tokenOrder.buyOffers[price].offers[tokenOrder.buyOffers[price].numOfOffers] = Offer(amount, user);
        
        if (tokenOrder.buyOffers[price].numOfOffers == 1) {
            tokenOrder.buyOffers[price].firstOffer = 1;
            tokenOrder.buyCount = tokenOrder.buyCount.add(1);
            uint currPrice = tokenOrder.maxBuyPrice;
            uint minPrice = tokenOrder.minBuyPrice;
            
            if (minPrice == 0 || minPrice >= price) {
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
                
            } else if (currPrice <= price) {
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
    
    function sellOffer(address user, address token, uint price, uint amount) public {
        uint totalPrice = price.mul(amount);
        require(user_wallet.token_balanceOf(user, token) >= amount);
        OrderBook storage tokenOrder = tokenBooks[token];
        //user_wallet.sub_eth(user, totalPrice);
        if (tokenOrder.buyCount == 0 || price < tokenOrder.maxBuyPrice) { //create new order if we have nothing to process
            storeSellOrder(user, token, price, amount);
        } else { //instanly execute order if it is possible
            uint ethAmount = 0;
            uint remain = amount;
            uint sellPrice = tokenOrder.minSellPrice;
            uint offCounter;
            while (sellPrice >= price && remain > 0) { //order execution loop
                offCounter = tokenOrder.buyOffers[sellPrice].firstOffer;
                while (offCounter <= tokenOrder.buyOffers[sellPrice].numOfOffers && remain > 0) {
                    uint currAmount = tokenOrder.buyOffers[sellPrice].offers[offCounter].amount;
                    if (currAmount <= remain) {
                        ethAmount = currAmount * sellPrice;
                        user_wallet.send_eth(tokenOrder.buyOffers[sellPrice].offers[offCounter].user, user, ethAmount);
                        user_wallet.send_token(user, tokenOrder.buyOffers[sellPrice].offers[offCounter].user, token, currAmount);
                        tokenOrder.buyOffers[sellPrice].offers[offCounter].amount = 0;
                        tokenOrder.buyOffers[sellPrice].firstOffer = tokenOrder.buyOffers[sellPrice].firstOffer.add(1);
                        remain = remain.sub(currAmount);
                    } else {
                        require(tokenOrder.buyOffers[sellPrice].offers[offCounter].amount >= remain);
                        ethAmount = remain * sellPrice;
                        user_wallet.send_eth(tokenOrder.buyOffers[sellPrice].offers[offCounter].user, user, ethAmount);
                        user_wallet.send_token(user, tokenOrder.buyOffers[sellPrice].offers[offCounter].user, token, remain);
                        tokenOrder.buyOffers[sellPrice].offers[offCounter].amount = tokenOrder.buyOffers[sellPrice].offers[offCounter].amount.sub(remain);
                        remain = 0;
                    }
                    if (offCounter == tokenOrder.buyOffers[sellPrice].numOfOffers && tokenOrder.buyOffers[sellPrice].offers[offCounter].amount == 0) {
                        tokenOrder.buyCount = tokenOrder.buyCount.sub(1);
                        if (sellPrice == tokenOrder.buyOffers[sellPrice].prevPrice || tokenOrder.buyOffers[sellPrice].prevPrice == 0) {
                            tokenOrder.maxBuyPrice = 0;
                        } else {
                            tokenOrder.maxBuyPrice = tokenOrder.buyOffers[sellPrice].prevPrice;
                            tokenOrder.buyOffers[tokenOrder.buyOffers[sellPrice].prevPrice].nextPrice = tokenOrder.maxBuyPrice;
                        }
                    }
                    offCounter = offCounter.add(1);
                }
                sellPrice = tokenOrder.maxBuyPrice;
            }
            if (remain > 0) {
                sellOffer(user, token, price, remain);
            }
        }
    }
    
    function storeSellOrder (address user, address token, uint price, uint amount) public {
        OrderBook storage tokenOrder = tokenBooks[token];
        tokenOrder.sellOffers[price].numOfOffers = tokenOrder.sellOffers[price].numOfOffers.add(1);
        tokenOrder.sellOffers[price].offers[tokenOrder.sellOffers[price].numOfOffers] = Offer(amount, user);
        if (tokenOrder.sellOffers[price].numOfOffers == 1) {
            tokenOrder.sellOffers[price].firstOffer = 1;
            tokenOrder.sellCount = tokenOrder.sellCount.add(1);
            uint currPrice = tokenOrder.minSellPrice;
            uint maxPrice = tokenOrder.maxSellPrice;
            
            if (maxPrice == 0 || maxPrice < price) {
                if (currPrice == 0 ) {
                    tokenOrder.minSellPrice = price;
                    tokenOrder.sellOffers[price].nextPrice = 0;
                    tokenOrder.sellOffers[price].prevPrice = 0;
                } else {
                    tokenOrder.sellOffers[maxPrice].nextPrice = price;
                    tokenOrder.sellOffers[price].prevPrice = maxPrice;
                    tokenOrder.sellOffers[price].nextPrice = price;
                }
                tokenOrder.maxSellPrice = price;
            } else if (currPrice > price) {
                tokenOrder.sellOffers[currPrice].prevPrice = price;
                tokenOrder.sellOffers[price].nextPrice = currPrice;
                tokenOrder.sellOffers[price].prevPrice = 0;
                tokenOrder.minSellPrice = price;
            } else {
                uint sellPrice = tokenOrder.minSellPrice;
                bool done = false;
                while (sellPrice > 0 && !done) {
                    if (sellPrice <= price && price <= tokenOrder.sellOffers[sellPrice].nextPrice) {
                        tokenOrder.sellOffers[price].prevPrice = sellPrice;
                        tokenOrder.sellOffers[price].nextPrice = tokenOrder.sellOffers[sellPrice].nextPrice;
                        tokenOrder.sellOffers[tokenOrder.sellOffers[sellPrice].nextPrice].prevPrice = price;
                        tokenOrder.sellOffers[sellPrice].nextPrice = price;
                        done = true;
                    }
                    sellPrice = tokenOrder.sellOffers[sellPrice].nextPrice;
                }
            }
        }
    }
}
