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
}

contract GasEfficientVoting {

    uint8 public proposalCounts;

    mapping (uint8 => Proposal) public proposals;
    mapping (address => uint8) private voteRegistry;

    event CreateProposal(uint8 indexed proposalId, bytes32 name);
    event Voted(address indexed voter, uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(
        bytes32 name, 
        uint32 duration
    ) public {}

    function voteProposal() public {}

    function executeProposal() public {}

    function getProposal() public {}
}