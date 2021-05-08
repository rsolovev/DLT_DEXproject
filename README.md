# DLT DEX Project
```
Mariia Charikova m.charikova@innopolis.ru
Igor Krasheninnikov i.krasheninnikov@innopolis.ru
Roman Solovev r.solovev@innopolis.ru
```

## Architectural diagram:  
DLT.png![image](https://user-images.githubusercontent.com/33293223/117545768-da753d00-b02f-11eb-875d-f04df5e1488d.png)

## API
API is a Web3 Python app, which will be a proxy between user and DEX smart contracts. User will call functions within this app and the app will send the orders and ethereum to DEX.
## Smart Contracts
### OrderBook
OrderBook is a smart contract which stores current DOM (Depth of Market) and when new order arrives (sell/buy) it will send the associated ethereum and tokens to DEX Wallet, then it will call the Matching engine smart contract to check if new order applies to perform a buy/sell operation.
### Mattching engine
Matching engine is a smart contract which recieves a OrderBook state and tries to match current buy/sell bids and if it succeedes, it will send a task to DEX wallet to send ethereum/tokens to associated users and a task for OrderBook to delete matched entries.
### DEX Wallet
DEX Wallet is a smart contract which stores the etherium/tokens of current bids and sends them to users, when Matching engine finds a match. 
### ERC20 Token
An ERC20 token contract, that would be thadable for ETH on our DEX
