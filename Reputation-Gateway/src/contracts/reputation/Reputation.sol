// SPDX-License-Identifier: ISC
pragma solidity ^0.8.1;

contract Reputation {
    
    // Reputation Variables
    struct StaticRep{
        address seller;      // address seller
        uint timestamp;
    }
    
    struct NegativeStaticRep{
        address seller;      // address seller
        uint timestamp;
    }
    
    mapping(address => StaticRep[]) staticReps;  // seller => StaticRep
    mapping(address => NegativeStaticRep[]) negativeStaticReps;  // seller => NegetiveStaticRep

    // count of static reps
    function getStaticReps(address _seller) external view returns (uint) {
        return staticReps[_seller].length;
    }
    
    // count of negetive static reps
    function getNegetiveStaticReps(address _seller) external view returns (uint) {
        return negativeStaticReps[_seller].length;
    }

    // fetch seller with reputations timestamp
    function dateOfTransactions(address _seller) external view returns (StaticRep[] memory) {
            return staticReps[_seller];
    }
    
    // fetch seller with reputations timestamp
    function dateOfNegetiveTransactions(address _seller) external view returns (NegativeStaticRep[] memory) {
            return negativeStaticReps[_seller];
    }
}