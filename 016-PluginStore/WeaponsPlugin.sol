// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract WeaponStorePlugin {

    mapping (address => string) private equippedWeapon;

    function setWeapon(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }

    function getWeapon(address user) public view returns (string memory) {
        return equippedWeapon[user];
    }
}