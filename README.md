# DLT DEX Project
```
Mariia Charikova m.charikova@innopolis.ru
Igor Krasheninnikov i.krasheninnikov@innopolis.ru
Roman Solovev r.solovev@innopolis.ru
```

## Architectural diagram:  
![image](https://user-images.githubusercontent.com/33293223/117657699-8b034e00-b1a2-11eb-96f4-804f3101d2a1.png)

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

## Launch Instructions
1. Install Ganache app for local network, install flask, web3 python packakges
2. Add some accounts from Ganache to `accounts.json` (example provided)
3. Add service account (to deploy Wallet and OrderBook contracts) to `service_account` (also from Ganache)
4. Launch `python3 deploy_contracts.py` to deploy Wallet, OrderBook and sample token contracts, their addresses will be stored in `database.json`
5. Launch the web interface: `python3 -m flask run` in the repository root directory
6. Go to 127.0.0.1:5000, there will be a starting page with account selection:  
  <img width="576" alt="изображение" src="https://user-images.githubusercontent.com/33293285/117690013-083ebb00-b1c3-11eb-8875-4879c30562b7.png">
