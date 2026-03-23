// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a simple voting system where users can vote on proposals. Your challenge is to make it as gas-efficient as possible. 
    Optimize how you store voter data, handle input parameters, and design functions. You'll learn how `calldata`, `memory`, and 
    `storage` affect gas usage and discover small changes that lead to big savings. It's like designing a voting machine that runs 
    faster and cheaper without losing accuracy.
*/

struct Proposal {
    string name;
    uint256 counts;
    uint256 startTime;
    uint256 endTime;
    bool ended;
}

contract Voting {

    Proposal[] public proposals;
    mapping (address => mapping (uint256 => bool)) usersVote;
    
    function createProposal(
        string memory name,
        uint256 durationInSec
    ) public {
        Proposal memory proposal = Proposal({
            name: name, 
            counts: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + durationInSec,
            ended: false
        });
        proposals.push(proposal);
    }

    function makeVote(uint256 proposalIndex) public {

        require(proposals[proposalIndex].startTime==0, "Proposal doesn't exists");
        require(proposals[proposalIndex].ended || block.timestamp > proposals[proposalIndex].endTime, "Proposal already ended!");
        usersVote[msg.sender][proposalIndex] = true;
        proposals[proposalIndex].counts++;
    }

    function executeProposal(uint256 proposalIndex) public {
        require(proposals[proposalIndex].startTime==0, "Proposal doesn't exists");
        require(proposals[proposalIndex].ended || block.timestamp > proposals[proposalIndex].endTime, "Proposal already ended!");
        proposals[proposalIndex].ended = true;   
    }
}