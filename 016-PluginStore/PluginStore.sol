// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a modular profile system for a Web3 game. The core contract stores each player's basic profile (like name and avatar), 
    but players can activate optional 'plugins' to add extra features like achievements, inventory management, battle stats, or social 
    interactions. Each plugin is a separate contract with its own logic, and the main contract uses `delegatecall` to execute plugin 
    functions while keeping all data in the core profile. This allows developers to add or upgrade features without redeploying 
    the main contract—just like installing new add-ons in a game. You'll learn how to use `delegatecall` safely, manage 
    execution context, and organize external logic in a modular way.

    Learning - delegatecall, code execution context, libraries.
*/

struct Player {
    bytes32 name;
    bytes32 avatar;
}

contract PluginStore {
    
    mapping (address => Player) public profiles;  // get Player's profile
    mapping (string => address) public plugins;   // register plugin

    function setProfile(string memory _name, string memory  _avatar) external {

        profiles[msg.sender] = Player({
            name: bytes32(bytes(_name)),
            avatar: bytes32(bytes(_avatar))
        });
    }

    function getProfile() external view returns (bytes32, bytes32) {
        Player memory playerProfile = profiles[msg.sender];
        return (playerProfile.name, playerProfile.avatar);
    }

    function registerPlugin(string memory key, address pluginAddress) external {
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns(address) {
        return plugins[key];
    }

    function runPlugin(
        string memory key, 
        string memory functionSignature, 
        address user, 
        string memory argument
    ) external {
        
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not found!");
        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);
        (bool success, ) = plugin.call(data);
        require (success, "Plugin execution failed!");
    }

    function runPluginView(
        string memory key, 
        string memory functionSignature, 
        address user
    ) external view returns(string memory) {

        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not found!");
        bytes memory data = abi.encodeWithSignature(functionSignature, user);
        (bool success, bytes memory result ) = plugin.staticcall(data);
        require (success, "Plugin execution failed!");
        return abi.decode(result, (string));
    }

    
}