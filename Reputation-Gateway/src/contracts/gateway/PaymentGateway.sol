// SPDX-License-Identifier: ISC

pragma solidity ^0.8.1;

import "../ownership/Ownership.sol";
import "../token/IERC20.sol";
import "../lib/SafeMath.sol";
import "../reputation/Reputation.sol";
import "../treasury/Treasury.sol";


contract PaymentGateway is Ownership, Reputation {
    
    using SafeMath for *;
    
    address payable public treasury;
    Treasury treasuryContract;
    address private auditor;
    
    uint constant private TREASURY_FEE_PERCENTAGE = 10;
    
    struct Good {
        address buyer;            // address of buyer
        uint price;               // price of craft
        string identidication;   // identidication of good
        uint8 status;             // 1: purchased , 2: finalized , 3: arbitrated
        IERC20 currency;           // currency of good
        bool isCurrencyToken;     // Ether or Token
    }
    
    Good[] public goods;
    
    // address ether :0x0000000000000000000000000000000000000000

    // emits when coins(not tokens) are transferred
    event CoinTransferred(address indexed sender, address indexed receiver, uint value);    
    // emits when tokens are transferred
    event TokenTransferred(address indexed sender, address indexed receiver, IERC20 currency, uint value); 
    // emits when good payed
    event GoodPayed(IERC20 currency, uint value, string identidication);
    
    // address of msg.sender
    function _msgSender() internal view returns (address) {                
        return msg.sender;
    }

    // amount of msg.value
    function _msgValue() internal view returns (uint) {                     
        return msg.value;
    }
    
    constructor(address payable _treasury, address _auditor) {
        require(checkForSmartContract(_treasury),"Please do not use an external account");
        // initiate reputation
        treasuryContract = Treasury(_treasury);
        // set the treasury of gateway
        treasury = _treasury;  
        // set the address of auditor in case of voting for resolution
        require(_auditor == treasuryContract.owner(), "Auditor must be vault owner");
        auditor = _auditor;
    }

    // checks an address / contract or EOA
    function checkForSmartContract(address _address) internal view returns(bool) {             
        uint size;
        assembly{
            size:= extcodesize(_address)
        }
        if (size > 0) {
            // this is a smart contract
            return true;
        }
        else return false;
    }
    
    // trasnfer currencies from gateway to any EAO
    function transferTo(address _recipient, uint256 _value, IERC20 _currency) public {      
        require(_msgSender() == auditor, "you are not auditor");
        require(!checkForSmartContract(_recipient),"Please use an External account. You cannot send your coins to other contracts");
        if (address(_currency) == address(0x0)) { 
            require(_value <= address(this).balance, "not enough balance");
            payable(_recipient).transfer(_value);
            emit CoinTransferred(address(this), _recipient, _value);
        } 
        else { // use Token
            require(checkForSmartContract(address(_currency)), "Invalid Contract address");
            require(_value <= _currency.balanceOf(address(this)), "not enough Token balance");
            require(_currency.transfer(_recipient, _value),  "token transfer failed failed");
            // event for transfer to any wallet
            emit TokenTransferred(address(this), _recipient , _currency, _value);    
        }
    }
    
    // trasnfer currencies from gateway to owner
    function withdraw(uint256 _value, IERC20 _currency) public {  
        require(_msgSender() == auditor, "you are not auditor");
        if (address(_currency) == address(0x0)) { 
            require(_value <= address(this).balance, "not enough balance");
            payable(owner).transfer(_value);
            emit CoinTransferred(address(this), owner, _value);
        } 
        else { // use Token
            require(checkForSmartContract(address(_currency)), "Invalid Contract address");
            require(_value <= _currency.balanceOf(address(this)), "not enough Token balance");
            require(_currency.transfer(owner, _value),  "token transfer failed failed");
            // event for transfer to owner
            emit TokenTransferred(address(this), owner , _currency, _value);                       
        }
    }
    
    // costumers call this and transfer currency to gateway
    function buy(uint _value, IERC20 _currency, string memory _identidication) public payable { 
        
        require(_msgSender() != owner, "you cannot buy on your gateway");
        
        
        if (address(_currency) == address(0x0)) { 
            require(_msgValue() == _value, "Coin value doesn't match offer");
            
            goods.push(Good({
            buyer: _msgSender(),
            price: _value,
            identidication: _identidication,
            isCurrencyToken: false,
            currency: _currency,
            status: 1
            }));
                      
            emit CoinTransferred(_msgSender(), address(this), _value);
        } 
        else { // use Token
            
            goods.push(Good({
            buyer: _msgSender(),
            price: _value,
            identidication: _identidication,
            isCurrencyToken: true,
            currency: _currency,
            status: 1
            }));
            
            require(checkForSmartContract(address(_currency)), "Invalid Contract address");
            require(_msgValue() == 0, "Coin would be lost");
            require(_currency.transferFrom(_msgSender(), address(this), _value),  "transferFrom failed");
            
            // event for transfer from to contract
            emit TokenTransferred(_msgSender(), address(this), _currency, _value); 
        }
        
        // good payedout
        emit GoodPayed(_currency, _value, _identidication);
    }
    
    function finalize(uint _goodIdx) public {
        
        Good storage good = goods[_goodIdx];
        require(_msgSender() == good.buyer, "you are not buyer");
        require(good.status == 1, "already finalized");
        
        uint temp = SafeMath.div(good.price, 100);
        uint fee = SafeMath.mul(temp, TREASURY_FEE_PERCENTAGE);
        uint payment = SafeMath.sub(good.price, fee);
        good.status = 2;
        
        if(good.isCurrencyToken == true){
            require(good.currency.transfer(treasury, fee),  "token transfer failed failed");
            emit TokenTransferred(address(this), treasury , good.currency, fee); 
            
            // pay owner
            require(good.currency.transfer(owner, payment),  "token transfer failed failed");
            // event for transfer to owner
            emit TokenTransferred(address(this), owner , good.currency, payment);
            
        } else if (good.isCurrencyToken == false){
            require(fee <= address(this).balance, "not enough balance");
            treasury.transfer(fee); 
            emit CoinTransferred(address(this), treasury, fee);
            
            // pay owner
            payable(owner).transfer(payment);
            emit CoinTransferred(address(this), owner, payment);
        }
        
        staticReps[owner].push(StaticRep({seller: owner, timestamp: block.timestamp}));
    }
    
    function vote(uint _goodIdx,uint8 _rule) public {   // 1: Seller, 2: Buyer
        
        require(_msgSender() == auditor, "you are not auditor");
        Good storage good = goods[_goodIdx];
        require(good.status == 1, "already finalized");
        uint temp = SafeMath.div(good.price, 100);
        uint fee = SafeMath.mul(temp, TREASURY_FEE_PERCENTAGE);
        uint payment = SafeMath.sub(good.price, fee);
        
        if (_rule == 1){
            
            if(good.isCurrencyToken == true){
                require(good.currency.transfer(treasury, fee),  "token transfer failed failed");
                emit TokenTransferred(address(this), treasury , good.currency, fee); 
                
                // pay owner
            require(good.currency.transfer(owner, payment),  "token transfer failed failed");
            // event for transfer to owner
            emit TokenTransferred(address(this), owner , good.currency, payment);
            
            } else if (good.isCurrencyToken == false){
                require(fee <= address(this).balance, "not enough balance");
                treasury.transfer(fee); 
                emit CoinTransferred(address(this), treasury, fee);
                // pay owner
                payable(owner).transfer(payment);
                emit CoinTransferred(address(this), owner, payment);
            }
        
        staticReps[owner].push(StaticRep({seller: owner, timestamp: block.timestamp}));
        good.status = 3;
            
        } else if (_rule == 2){
    
             if(good.isCurrencyToken == true){
                require(good.currency.transfer(good.buyer, good.price),  "token transfer failed failed");
                emit TokenTransferred(address(this), good.buyer, good.currency, good.price); 
            
            } else if (good.isCurrencyToken == false){
                require(good.price <= address(this).balance, "not enough balance");
                payable(good.buyer).transfer(good.price); 
                emit CoinTransferred(address(this), good.buyer, good.price);
            }
        negativeStaticReps[owner].push(NegativeStaticRep({seller: owner, timestamp: block.timestamp}));
        good.status = 3;
            
        }
    }
    
    // balance of available currencies in gateway
    function getBalance(IERC20 _currency) public view onlyOwner returns (uint balance) {       
        if (address(_currency) == address(0x0)) { 
            return address(this).balance;
        }
        else {
            require(checkForSmartContract(address(_currency)), "Invalid Contract address");
            return _currency.balanceOf(address(this));
        }
    }
}