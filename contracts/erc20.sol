pragma solidity ^0.6.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;  
    
    address public owner_;
    address public baseAddress;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) public balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


    constructor(uint256 total, string memory _name,string memory _symbol, uint8 _decimals, address _owner) public {  
    	totalSupply_ = total;
    	balances[_owner] = totalSupply_;
    	name =  _name;
    	symbol = _symbol;
    	decimals=_decimals;
    	owner_ = _owner;
    	baseAddress = address(this);
    }

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address ownerIn,address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[ownerIn]);
        balances[ownerIn] = balances[ownerIn].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(ownerIn, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}