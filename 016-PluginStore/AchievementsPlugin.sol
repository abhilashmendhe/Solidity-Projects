// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract AchievementPlugin {

    mapping (address => string) private latestAchievement;

    function setAchievement(address user, string memory achieivement) external {
        latestAchievement[user] = achieivement;
    }

    function getAchievement(address user) public view returns(string memory) {
        return latestAchievement[user];
    }
}