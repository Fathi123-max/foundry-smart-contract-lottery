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

import {VRFConsumerBaseV2Plus} from "@chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/* Errors*/

error Raffle_NotEnoughETH();
error Raffle__TransferFailed();
error Raffle__WaitForNextTime();
error Raffle__UpkeepNotNeeded(
    uint256 balance,
    uint256 playerLength, // Fixed typo
    uint256 raffleState
);

/// @title A Simple Raffle contract
/// @author Fathi Wehba <https://github.com/Fathi123-max>
/// @notice This contract is a creating a simple raffle
/// @dev Its implements Chainlink VRFv2.5 for randomness and ChainLink Automatic contract for payments
contract Raffle is VRFConsumerBaseV2Plus {
    // Type declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    RaffleState private s_raffleState;

    uint256 private immutable i_entranceFees;
    address payable[] private s_players;
    uint256 public immutable i_interval;
    uint256 public immutable s_lastTimeStamp;
    address payable private s_recentWinner;

    // Chainlink VRF Variables
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    bool private constant NATIVE_PAYMENT = false;

    /*Events*/
    event EnteredRaffle(address indexed player);
    event Winner(address indexed winner);

    /*Constructor*/
    constructor(
        uint256 entranceFees,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFees = entranceFees;
        i_interval = interval;

        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_requestConfirmations = requestConfirmations;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value < i_entranceFees, "Not enough ETH");
        if (msg.value < i_entranceFees) revert Raffle_NotEnoughETH();
        //check Raffel is opened
        if (s_raffleState != RaffleState.OPEN) revert Raffle__WaitForNextTime();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicitly, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool interval_passed = (block.timestamp - s_lastTimeStamp) >=
            i_interval;
        bool is_lottary_opned = s_raffleState == RaffleState.OPEN;

        bool is_contract_has_eth = address(this).balance > 0;

        bool is_there_is_players = s_players.length > 0;

        upkeepNeeded =
            interval_passed &&
            is_contract_has_eth &&
            is_lottary_opned &&
            is_there_is_players;

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: NATIVE_PAYMENT})
                )
            })
        );
    }

    /*Getters Functions*/
    function getEntranceFees() public view returns (uint256) {
        return i_entranceFees;
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal virtual override {
        uint256 randomNumber = randomWords[0];

        uint256 winnerPostion = randomNumber % s_players.length;
        address payable winner = s_players[winnerPostion];
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp == block.timestamp;

        s_recentWinner = winner;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit Winner(s_recentWinner);
    }
}
