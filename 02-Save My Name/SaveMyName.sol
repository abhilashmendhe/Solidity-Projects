// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version

/*
    Imagine creating a basic profile. You'll make a contract where users can save their name (like 'Alice') and a short bio (like 'I build dApps'). 
    You'll learn how to store text (using `string`) on the blockchain. Then, you'll create functions to let users save and retrieve this information. 
    This demonstrates how to store and retrieve data on the blockchain, essential for building profiles or user data storage.
*/

contract SaveMyName {

    string name;
    string bio;
    bool employed;

    function saveInformation(string memory _name, string memory _bio, bool _employed) public {
        name = _name;
        bio = _bio;
        employed = _employed;
    }

    function getInformation() public view returns(string memory, string memory, bool) {
        return (name, bio, employed);
    }

}