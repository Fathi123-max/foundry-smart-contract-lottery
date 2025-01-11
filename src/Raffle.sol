// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private

// view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

/// @title A Simple Raffle contract
/// @author Fathi Wehba <https://github.com/Fathi123-max>
/// @notice This contract is a creating a simple raffle
/// @dev Its implements Chainlink VRFv2.5 for randomness and ChainLink Automatic contract for payments
contract Raffle {
    uint256 private immutable i_entranceFees;

    /*Constructor*/
    constructor(uint256 entranceFees) {
        i_entranceFees = entranceFees;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /*Getters Functions*/
    function getEntranceFees() public view returns (uint256) {
        return i_entranceFees;
    }
}
