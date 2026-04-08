// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.31;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    IEntryPoint private immutable I_ENTRYPOINT;

    modifier requireFromEntryPoint() {
        _requireFromEntryPoint();
        _;
    }
    modifier requireFromEntryPointOrOwner() {
        _requireFromEntryPointOrOwner();
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        I_ENTRYPOINT = IEntryPoint(entryPoint);
    }

    receive() external payable {}

    // -------------------------- EXTERNAL FUNCTIONS --------------------------
    function execute(address dest, uint256 value, bytes calldata functionData) external requireFromEntryPoint {
        (bool success, bytes memory result) = dest.call{value: value}(functionData);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    // A signature is valid, it it's a MinimalAccount owner
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNounce();
        _payPrefund(missingAccountFunds);
    }

    function getEntryPoint() external view returns (address) {
        return address(I_ENTRYPOINT);
    }

    // -------------------------- INTERNAL FUNCTIONS --------------------------
    // owner of this conract will validate signature
    // userOpHash is EIP-191 version of signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    function _requireFromEntryPointOrOwner() internal view {
        if (msg.sender != address(I_ENTRYPOINT) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
    }

    function _requireFromEntryPoint() internal view {
        if (msg.sender != address(I_ENTRYPOINT)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
    }
}
