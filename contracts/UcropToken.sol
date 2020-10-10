// contracts/UcropToken.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Brain.sol";
import "./CDP.sol";

contract UcropToken is Ownable {
    
    string public constant name = "Ucrop token";
    string public constant symbol = "ucr";
    uint32 constant public decimals = 18;
    uint32 public rate = 2; 
    uint256 public totalSupply ;
    address public BrainAddress;
    mapping(address=>uint256) public balances;
    mapping (address => mapping(address => uint)) allowed;
    
  function mint(address  _to, uint _value, uint _depositedEther) internal {
    assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
    balances[_to] += _value;
    totalSupply += _value;
    
    Brain b = Brain(BrainAddress);
    b.createNewCDP(_depositedEther, _to, _value);  //вызов функции создания CDP в Brain
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public returns (bool success) {
      if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) 
      {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      }
      return false;
    }
  
  function StartClosingCDP(address _CDP, uint _value) 
  public
  {
      require(balances[msg.sender] >= _value /* && balances[address(this)] + _value >= balances[address(this)]*/, "Баланс даного клиента меньше");
      Brain b = Brain(BrainAddress);
      b.startKillingCDP(_CDP, _value, msg.sender);
      balances[msg.sender] -= _value;
      balances[address(this)] += _value;
      Transfer(msg.sender, address(this), _value);
      
      uint EtherDeposit = b.deleteAllCDPInfo(_CDP);
      msg.sender.transfer(EtherDeposit);
      //totalSupply = totalSupply - _value;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    if( allowed[_from][msg.sender] >= _value &&
    balances[_from] >= _value
    && balances[_to] + _value >= balances[_to]) {
      allowed[_from][msg.sender] -= _value;
      balances[_from] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);

  event Approval(address indexed _owner, address indexed _spender, uint _value);

  function getTokenAmount(uint256 _value) internal view returns (uint256) {
    return _value / rate;
  }

  function setRate(uint32 _value) public
  onlyBrain
  {
      rate = _value;
  }
  
  function getRate() public view returns (uint32) {
      return rate;
  }

  modifier onlyBrain()
  {
      require(msg.sender == BrainAddress, "только Brain может устанавливать rate");
      _;
  }

  function setBrainAddress(address _newBrainAddress)
  public
  onlyOwner
  {
      BrainAddress = _newBrainAddress;
  }


  receive() external payable {
    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(weiAmount);
    mint(msg.sender, tokens, weiAmount);
  }

}