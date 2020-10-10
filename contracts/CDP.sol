// contracts/CDP.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/

import "./UcropToken.sol";

contract CDP is Ownable {
    
    uint256 public EtherDeposited; //количество заблокированного эфира, на этом CDP
    uint256 public lastRateInfo; //последняя полученная информация о курсе Эфира
    uint256 public UcropGiven;
    address public clientAddress; //адрес покупателя токенов
    bool public canBeClosedOnlyByClient = true; //флаг, что CDP может быть закрыт только покупателем токенов
    uint256 tokenAmount;
    address tokenAddress;//когда токен будет задеплоен, станет доступен

    constructor (uint256 _EtherDeposited, uint256 _lastRateInfo, address _clientAddress, uint _UcropGiven) public {
        EtherDeposited = _EtherDeposited;
        lastRateInfo = _lastRateInfo;
        clientAddress = _clientAddress;
        //tokenAmount = calcTokenAmount(_lastRateInfo);
        UcropGiven = _UcropGiven;
    }
    
    function getRateInfo(uint _1EtherCost) 
        external
        onlyOwner()
    {
        lastRateInfo = _1EtherCost;
        
        //в случае, если курс Эфира ниже допустимого минимума
        if(lastRateInfo < 75)
        {
            toAuctionOff();
        }
    }

    //выставление содержимого CDP на открытый аукцион
    function toAuctionOff()
        private
    {
        canBeClosedOnlyByClient = false;
    }
    
    function killCDP() 
    public
    onlyOwner()
    {
        renounceOwnership();
        //address payable theOwner;
        //theOwner = owner();
        //selfdestruct(theOwner);
    }
}
