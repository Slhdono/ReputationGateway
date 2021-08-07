// SPDX-License-Identifier: ISC

pragma solidity ^0.8.1;

import "../ownership/Ownership.sol";
import "../token/ERC20.sol";
import "../lib/SafeMath.sol";

contract Treasury is Ownership{
    
    // emits when coins(not tokens) are transferred
    event CoinTransferred(address indexed sender, address indexed receiver, uint value);    
    // emits when tokens are transferred
    event TokenTransferred(address indexed sender, address indexed receiver, ERC20 currency, uint value); 
    
    // address ether :0x0000000000000000000000000000000000000000

    fallback() external payable {}
    
    receive() external payable {}
    
    mapping(address => bool)  allowedMiners;
    
    ERC20 RPT;
    
    constructor(address _rptToken) {
        RPT = ERC20(_rptToken);
        
        require(owner == RPT.owner(), "you need to be RPT owner");
    }
    
    function addMiner(address _miner) public onlyOwner {
        require(RPT.stakeOf(_miner) >= 100 ,"This miner did not stake enough to become miner!");
        allowedMiners[_miner] = true;
    }
    
    function removeMiner(address _miner) public onlyOwner {
        require(RPT.stakeOf(_miner) == 0 ,"This miner still has stake, you cannot remove them!");
        allowedMiners[_miner] = false;
    }

    function isMiner(address _miner) public view returns(bool) {
        return allowedMiners[_miner];
    }
    
    function sendMinerReward(ERC20 _currency, address _miner, uint _value) public onlyOwner {
        require(allowedMiners[address(this)] || allowedMiners[_miner],"This is not a valid miner!");
        if (address(_currency) == address(0x0)) {
            require(_value <= address(this).balance, "not enough balance");
            payable(_miner).transfer(_value);
            emit CoinTransferred(address(this), _miner, _value);
        } else {
            require(_value <= _currency.balanceOf(address(this)), "not enough Token balance");
            require(_currency.transfer(_miner, _value),  "token transfer failed failed");
            // event for transfer to owner
            emit TokenTransferred(address(this), _miner , _currency, _value);  
        }
    }
    
    function withdraw(ERC20 _currency, uint _value) public onlyOwner {
        if (address(_currency) == address(0x0)) {
            require(_value <= address(this).balance, "not enough balance");
            payable(owner).transfer(_value);
            emit CoinTransferred(address(this), owner, _value);
        } else {
            require(_value <= _currency.balanceOf(address(this)), "not enough Token balance");
            require(_currency.transfer(owner, _value),  "token transfer failed failed");
            // event for transfer to owner
            emit TokenTransferred(address(this), owner , _currency, _value);  
        }
    }
    
}