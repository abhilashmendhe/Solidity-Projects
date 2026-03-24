// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    What we learn here is:
    Gas optimization, Efficient data locations, Calldata vs memory, Minimizing storage writes
*/

struct Proposal {
    bytes32 name;
    uint32 voteCounts;
    uint32 startTime;
    uint32 endTime;
    bool votingEnded;
    address owner;
}

contract GasEfficientVoting {

    error Voting__NoProposals();
    error Voting__OwnerCannotVote();
    error Voting__ProposalExecuted();
    error Voting__LimitProposals(string message);

    uint8 public proposalCounts = 1;

    mapping (uint8 => Proposal) public proposals;
    mapping (address => uint256) private voteRegistry;

    event CreateProposal(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(address indexed owner, uint8 indexed proposalId);

    function createProposal(
        string memory name, 
        uint32 duration
    ) public {
        require(duration >= 600, "Duration should be atleast 600 seconds.");

        Proposal memory newProposal = Proposal({
            name: bytes32(bytes(name)), 
            voteCounts: 0,
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + duration,
            votingEnded: false,
            owner: msg.sender
        });

        proposals[proposalCounts] = newProposal;

        emit CreateProposal(proposalCounts, bytes32(bytes(name)));
        proposalCounts++;
    }

    function voteProposal(uint8 proposalId) public returns(uint256){

        if (proposals[proposalId].owner == address(0)) revert Voting__NoProposals();
        if (proposals[proposalId].votingEnded == true) revert Voting__ProposalExecuted();
        if (proposals[proposalId].owner == msg.sender) revert Voting__OwnerCannotVote();
        if (proposalId < 0 && proposalId > 256) revert Voting__LimitProposals("Proposal IDs from 1 - 255");

        // use bit shift to check how many votes made by current user(msg.sender)
        uint256 userSetBitInd = 1 << proposalId;
        voteRegistry[msg.sender] |= userSetBitInd;

        emit Voted(msg.sender, proposalId);

        uint256 userBitVal = voteRegistry[msg.sender];
        uint256 setBitCount = 0;
        while (userBitVal>0) {
            userBitVal &= (userBitVal-1);
            setBitCount++;
        }

        return setBitCount;
    }

    function executeProposal(uint8 proposalId) public {
        if (proposals[proposalId].owner == address(0)) revert Voting__NoProposals();
        if (proposals[proposalId].votingEnded == true) revert Voting__ProposalExecuted();
        require(proposals[proposalId].owner == msg.sender,"Only owner can execute the proposals.");

        proposals[proposalId].votingEnded = true;     
        emit ProposalExecuted(msg.sender, proposalId);
    }

    function getProposal() public {}
}