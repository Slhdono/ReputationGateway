// SPDX-License-Identifier: ISC
pragma solidity ^0.8.1;

contract Ownership {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  //Sets owner
  constructor() {
    owner = msg.sender;
  }

  //Only owner has permission to call the function, when function uses this modifier
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //Allows the current owner to transfer control of the contract to a newOwner.
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
