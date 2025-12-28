// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version

/*
    Let's build a simple polling station! Users will be able to vote for their favorite candidates.
    You'll use lists (arrays, `uint[]`) to store candidate details. 
    You'll also create a system (mappings, `mapping(address => uint)`) to remember who (their `address`) voted for which candidate. 
    Think of it as a digital voting booth. This teaches you how to manage data in a structured way.
*/

contract PollStations {

    struct Candidate {
        string name;
        address addr;
    }
    Candidate[] candidates;
    mapping (address => uint256) public voteCount;

    function addCandidate(address _owner, string memory _name) public {
        candidates.push(Candidate(_name, _owner));
    }

    function getCandidate(address _owner) public view returns (Candidate memory) {
        
        Candidate memory tCand;
        for (uint i=0; i<candidates.length; i++) {
            if (candidates[i].addr == _owner) {
                tCand = candidates[i];
            }
        }
        return tCand;
    }
    function allCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }
    function voteCandidate(address _owner) public {
        voteCount[_owner]++;
    }
    function getVoteCandidate(address _owner) public view returns (uint256) {
        return voteCount[_owner];
    }
}