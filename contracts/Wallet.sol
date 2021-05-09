pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Wallet {

    /*TODO: organize emits for transfer operations*/

    using SafeMath for uint256;

    event ethDeposit (address indexed account, uint256 amount);
    event ethWithdraw (address indexed account, uint256 amount);
    event tokenCreation (address indexed account, address indexed token, string name);

    struct userWallet {
        mapping(address => uint256) balances;
        uint256 eth_balance;
        bool valid;
    }

    mapping (address => userWallet) public wallets;
    address tokenAddr;

    constructor() public {
    }

    function createToken (address user, uint256 total, string memory name, string memory symbol, uint8 decimals) public {
        require (wallets[user].valid, "You should create wallet before usage");
        ERC20 c = new ERC20(total, name, symbol, decimals, user);
        wallets[user].balances[address(c)] = total;
        tokenCreation(user, c.baseAddress(), name);
        tokenAddr = c.baseAddress();
    }

    function create_wallet (address user) public {
        wallets[user] = userWallet(0, true);
    }

    function deposit_eth (address user) public payable {
        require (wallets[user].valid, "You should create wallet before usage");
        wallets[user].eth_balance = wallets[user].eth_balance.add(msg.value);
        ethDeposit(user, msg.value);
    }

    function withdraw (address payable user, uint256 amount) public {
        require (wallets[user].valid, "You should create wallet before usage");
        require (amount <= wallets[user].eth_balance, "You don't enough balance to withdraw");
        wallets[user].eth_balance = wallets[user].eth_balance.sub(amount);
        user.transfer(amount);
        ethWithdraw(user, amount);
    }

    function send_token (address user, address receiver, address tokenAddr, uint numTokens) public returns (bool){
        require (wallets[user].valid, "You should create wallet before usage");
        ERC20 tmp = ERC20(tokenAddr);
        tmp.transfer(user,receiver,numTokens);
        wallets[user].balances[tokenAddr] = tmp.balanceOf(user);
        wallets[receiver].balances[tokenAddr] = tmp.balanceOf(receiver);
        return true;
    }

    function eth_balanceOf (address tokenOwner) public view returns (uint) {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        return wallets[tokenOwner].eth_balance;
    }

    function token_balanceOf (address tokenOwner, address token) public view returns (uint) {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        return wallets[tokenOwner].balances[token];
    }

    function add_token (address user, address token_addr) public {
        require (wallets[user].valid, "You should create wallet before usage");
        ERC20 c = ERC20(token_addr);
        wallets[user].balances[token_addr] = c.balances(user);
    }

    function send_eth (address user, address receiver, uint256 amount) public {
        require (wallets[user].valid, "You should create wallet before usage");
        wallets[user].eth_balance = wallets[user].eth_balance.sub(amount);
        wallets[receiver].eth_balance = wallets[receiver].eth_balance.add(amount);
    }
    
    function sub_eth (address user, uint amount) public {
        require (wallets[user].valid, "You should create wallet before usage");
        require (wallets[user].eth_balance >= amount);
        wallets[user].eth_balance = wallets[user].eth_balance.sub(amount);
    }
    
    function add_eth (address user, uint amount) public {
        require (wallets[user].valid, "You should create wallet before usage");
        wallets[user].eth_balance = wallets[user].eth_balance.add(amount);
    }
    
    function sub_token_balance (address tokenOwner, address token, uint amount) public {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        require (wallets[tokenOwner].balances[token] >= amount);
        wallets[tokenOwner].balances[token] = wallets[tokenOwner].balances[token].sub(amount);
    }
    
    function add_token_balance (address tokenOwner, address token, uint amount) public {
        require (wallets[tokenOwner].valid, "You should create wallet before usage");
        wallets[tokenOwner].balances[token] = wallets[tokenOwner].balances[token].add(amount);
    }

    function get_symbol (address token) public view returns(string memory) {
        ERC20 c = ERC20(token);
        return c.symbol();
    }
}
