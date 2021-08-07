// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../lib/SafeMath.sol";
import "../ownership/Ownership.sol";
import "./IERC20.sol";

library Balances {
    
    using SafeMath for *;
    
    function move(mapping(address => uint256) storage balances, address sender, address receiver, uint amount) internal {
        require(balances[sender] >= amount);
        require(SafeMath.add(balances[receiver] , amount) >= balances[receiver]);
        balances[sender] = SafeMath.sub(balances[sender] ,amount);
        balances[receiver] = SafeMath.add(balances[receiver],amount);
    }
}

contract ERC20 is Ownership, IERC20{
    
    using Balances for *;
    using SafeMath for uint;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping (address => uint256)) private allowed;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    address[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    mapping(address => uint256) internal rewards;
    
    constructor () {
        _name = "Reputation Token";
        _symbol = "RPT";
        _decimals = 18;
        _totalSupply = 1000000000 * 10**18;
        balances[msg.sender] = _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function mint(uint _amount) external onlyOwner{
        _mint(msg.sender, _amount);
    }
    
    function burn(uint _amount) external onlyOwner{
        _burn(msg.sender, _amount);
    }

    function transfer(address receiver, uint amount) public override returns (bool success) {
        balances.move(msg.sender, receiver, amount);
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function transferFrom(address sender, address receiver, uint amount) public override returns (bool success) {
        require(allowed[sender][msg.sender] >= amount);
        allowed[sender][msg.sender] = SafeMath.sub(allowed[sender][msg.sender], amount);
        balances.move(sender, receiver, amount);
        emit Transfer(sender, receiver, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool success) {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function isStakeholder(address _address) public view returns (bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) {
            stakeholders.push(_stakeholder);
        }
    }
    
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder) {
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
    }
   
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder];
    }

    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }
   
    function createStake(uint256 _stake) public {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }
   
   function removeStake(uint256 _stake) public {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
   }
   
   function rewardOf(address _stakeholder) public view returns (uint256) {
        return rewards[_stakeholder];
   }
   
   function totalRewards() public view returns (uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
   }
   
   function calculateReward(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder] / 100;
   }
   
   function distributeRewards() public onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
   }
   
   function withdrawReward() public {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
  }
   
   function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
  }
  
  function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        balances[account] = balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
  }
}   