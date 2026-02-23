// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Abhilash
 * @notice A simple contract to create raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error SendMoreToEnterRaffle();
    error TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /**
     * Enums
     */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * Constant variables
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /**
     * State Variables
     */
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL; // duration of lottery in seconds
    address payable[] private sPlayers;
    uint256 private sLastTimeStamp;
    uint256 private immutable I_SUBSCRIPTION_ID;
    bytes32 private immutable I_KEY_HASH;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    address private sRecentWinner;
    RaffleState private sRaffleState;
    
    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        sLastTimeStamp = block.timestamp;
        I_KEY_HASH = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        sRaffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < I_ENTRANCE_FEE) {
            revert SendMoreToEnterRaffle();
        }
        if (sRaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        sPlayers.push(payable(msg.sender));

        // 1. Emit makes migration easier
        // 2. Emit makes front end (develoer) "indexing" easier
        emit RaffleEntered(msg.sender);
    }
    /**
     * This function is called by chainlink nodes to check if the lotter is ready to pick a winner
     * The following should be true in order for upkeepNeeded to be true
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH (has players)
     * 4. Implicitlly, your subscription has LINK
     */
    function checkUpKeep(
        bytes memory /*checkData*/
    ) public view
        returns (
            bool upkeepNeeded,
            bytes memory /* perforData */
        )
    {
        bool timeHasPassed = ((block.timestamp - sLastTimeStamp) >= I_INTERVAL);
        bool isOpen = sRaffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = sPlayers.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    // 1. Get a random number
    // 2. Use a random number to pick a player
    // 3. Be automatically called (use 'chainlink automation' previously known as 'chainlink keepers')
    // function pickWinner() external {
    function performUpkeep(bytes calldata /* performData */) external {
        // if ((block.timestamp - sLastTimeStamp) > I_INTERVAL) {
        //     revert();
        // }
        (bool upkeepNeeded, ) = checkUpKeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, sPlayers.length, uint256(sRaffleState));
        }

        sRaffleState = RaffleState.CALCULATING;

        // Get our random number
        // 1. Request RNG
        // 2. Get RNG
        VRFV2PlusClient.RandomWordsRequest memory randomWordRequest = VRFV2PlusClient.RandomWordsRequest({
            keyHash: I_KEY_HASH,
            subId: I_SUBSCRIPTION_ID,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(randomWordRequest);
    }

    // CEI: Checks, Effects, Interaction Patterns
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        // Checks
        // requires, conditionals etc

        // Effect (Internal Contract State)
        uint256 indexOfWinnder = randomWords[0] % sPlayers.length;
        address payable recentWinner = sPlayers[indexOfWinnder];
        sRecentWinner = recentWinner;

        sRaffleState = RaffleState.OPEN;
        sPlayers = new address payable[](0);
        sLastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);

        // Interactions (External contracts)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * Getter Function
     */
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}
