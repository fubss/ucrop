// contracts/Brain.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CDP.sol";

contract Brain is Ownable{
    
    uint256 public tokensAmount = 0;
    uint256 public maxUcropPerCDPValue = 1000;
    uint256 public maxUcropPerClient = 10000;
    uint256 public lastEtherRateInfo = 111;

    address payable public ucropTokenAddress;
    
    
    
    mapping(address=>uint256) public tokensPerClient; //учет количества токенов по каждому клиенту
    mapping(address=>address) public CDPHolder;  //Это и все, что ниже дешевле хранить в токене?
    mapping(address=>uint256) public CDPDeposit; //
    mapping(address=>uint256) public CDPUcropGiven; //
    //mapping(address=>uint32) public CDPEtherMinCost; // до сюда
    
    address[] public contracts; // index of created contracts
    mapping(address=>uint256) public CDPindexIncontracts;
    uint32 public aliveCDPsCount = 0;
    
    function setUcropTokenAddress(address payable _newUcropTokenAddress)
    onlyOwner
    public
    {
        ucropTokenAddress = _newUcropTokenAddress;
    }
    
    modifier onlyToken()
    {
        require(ucropTokenAddress == msg.sender);
        _;
    }

    function getContractCount() // useful to know the row count in contracts index
        public
        view
        returns(uint)
    {
        return aliveCDPsCount;
    }
    
    modifier isLimit(uint256 _amountToGet) {
        require(_amountToGet <= maxUcropPerCDPValue && _amountToGet > 0, "Желаемое количество превышает максимально возможное для одного CDP");
        require(tokensPerClient[msg.sender] + _amountToGet <= maxUcropPerClient, "Желаемое количество превышает максимально возможное для одного клиента");
        _;
    }

    function createNewCDP(uint256 _depositedEther, address _clientAddress, uint256 _givenTokens) //deploy a new contract
        //isLimit(_amountToGet)
        public
        onlyToken()
        returns(address newCDP)
    {
        CDP c = new CDP(_depositedEther, lastEtherRateInfo, _clientAddress, _givenTokens);
        contracts.push(address(c));
        CDPindexIncontracts[address(c)] = contracts.length - 1;
        aliveCDPsCount++;
        CDPHolder[address(c)] = _clientAddress;
        CDPDeposit[address(c)] = _depositedEther;
        CDPUcropGiven[address(c)] = _givenTokens;
        //CDPEtherMinCost[c] = 75;
        //c.transferOwnership(_clientAddress);
        tokensAmount = tokensAmount + _givenTokens;
        return address(c);
    }
    
    modifier CDPUcropGivenCheck(address _CDP, uint _value)
    {
        require(CDPUcropGiven[_CDP]==_value, "вы должны полностью вернуть то же количество токенов, сколько взяли у данного CDP");
        _;
    }
    
     modifier CDPHolderCheck(address _CDP, address _client)
    {
            require(CDPHolder[_CDP]==address(0) || CDPHolder[_CDP]==_client, "только владелец CDP может закрыть CDP");
            _;
    }
    
    function startKillingCDP(address _CDP, uint _value, address _client)
    onlyToken()
    CDPUcropGivenCheck(_CDP, _value)
    CDPHolderCheck(_CDP, _client)
    view
    public
    returns (bool successStartKilling)
    {
        return true;
    }
    
    function deleteAllCDPInfo(address _CDP) 
    onlyToken()
    public
    returns (uint DepositValue)
    {
        delete CDPUcropGiven[_CDP];
        delete CDPHolder[_CDP];
        DepositValue = CDPDeposit[_CDP];
        delete CDPDeposit[_CDP];
        uint256 index = CDPindexIncontracts[_CDP];
        contracts[index] = address(0);
        //delete contracts[index]; //TODO: корректное удаление индексов и логику просомтра CDP для клиентов
        CDP cdp = CDP(_CDP);
        cdp.killCDP();
        aliveCDPsCount--;
        return DepositValue;
    }
    
    //информация о курсе валюты
    function broadcastRate(uint _1EtherCost, uint32 _UcropEtherRatio)
        public
        onlyOwner
    {
        for(uint i=0; i < contracts.length; i++)
        {
            if(contracts[i]!=address(0))
            {
                CDP existingCDP = CDP(contracts[i]); //обращаемся к каждому адресу существующих CDP
                existingCDP.getRateInfo(_1EtherCost); //сообщаем им информацию о курсе эфира
                if(_1EtherCost<75)
                {
                    CDPHolder[contracts[i]]=address(0);
                }
            }
        }
        lastEtherRateInfo = _1EtherCost;
        
        UcropToken workingToken = UcropToken(ucropTokenAddress);
        workingToken.setRate(_UcropEtherRatio);  //сообщаем токену информацию о курсе Укропа к Эфиру
    }
}