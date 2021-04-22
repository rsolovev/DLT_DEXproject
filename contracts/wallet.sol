pragma solidity ^0.6.0;

import "contracts/erc20.sol";

contract wallet {
    
    using SafeMath for uint256;
    
    event ethDeposit (address indexed account, uint256 amount);
    event ethWithdraw (address indexed account, uint256 amount);
    
    struct userWallet {
        mapping(string => address) tokens;
        mapping(string => uint256) balances;
        uint256 eth_balance;
        bool valid;
    }
    
    mapping (address => userWallet) wallets;
    
    function createToken (uint256 total, string memory name, string memory symbol, uint8 decimals) public {
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        ERC20 c = new ERC20(total, name, symbol, decimals, msg.sender);
        wallets[msg.sender].tokens[symbol] = address(c);
        wallets[msg.sender].balances[symbol] = total;
        
    }
    
    function create_wallet () public {
        wallets[msg.sender] = userWallet(0, true);
    }
    
    function deposit_eth () public payable {
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        wallets[msg.sender].eth_balance.add(msg.value);
        ethDeposit(msg.sender, msg.value);
    }
    
    function withdraw (uint256 amount) public {
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        require (amount <= wallets[msg.sender].eth_balance, "You don't enough balance to withdraw");
        wallets[msg.sender].eth_balance.sub(amount);
        msg.sender.transfer(amount);
        ethWithdraw(msg.sender, amount);
    }
    
    function send_token (address receiver, string memory tokenSymbol, uint numTokens) public returns (bool){
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        ERC20 tmp = ERC20(wallets[msg.sender].tokens[tokenSymbol]);
        tmp.transfer(msg.sender,receiver,numTokens);
        wallets[msg.sender].balances[tokenSymbol] = tmp.balanceOf(msg.sender);
        wallets[receiver].balances[tokenSymbol] = tmp.balanceOf(receiver);
        return true;
    }
    
    function eth_balanceOf (address tokenOwner) public view returns (uint) {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        return wallets[tokenOwner].eth_balance;
    }
    
    function token_balanceOf (address tokenOwner, string memory symbol) public view returns (uint) {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        return wallets[tokenOwner].balances[symbol];
    }
    
    function add_token (address token_addr) public {
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        ERC20 c = ERC20(token_addr);
        wallets[msg.sender].tokens[c.symbol()] = token_addr;
        wallets[msg.sender].balances[c.symbol()] = c.balances(msg.sender);
    }
    
    function send_eth (address receiver, uint256 amount) public view {
        require (wallets[msg.sender].valid, "You should create wallet before usage");
        wallets[msg.sender].eth_balance.sub(amount);
        wallets[receiver].eth_balance.add(amount);
    }
}