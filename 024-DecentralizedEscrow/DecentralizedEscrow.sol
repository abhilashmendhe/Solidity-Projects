// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Escrow is a legal and financial arrangement where a neutral third party holds funds, assets, or documents on behalf of two 
    transacting parties until agreed-upon conditions are met. It ensures security by releasing assets only when obligations are fulfilled, 
    reducing risks of fraud or non-payment.
*/

enum EscrowState {
    AWAITING_PAYMENT,
    AWAITING_DELIVERY,
    COMPLETE,
    DISPUTED,
    CANCELLED
}

contract DecentralizedEscrow {

    address public immutable buyer;
    address public immutable seller;
    address public immutable aribiter; // trustted 3rd party that handles dispute

    EscrowState public state;

    uint256 public amount;
    uint256 public depositTime;
    uint256 public deliveryTimeout;

    event PaymentDesposited(address indexed user, uint256 amount);
    event deliveryConfirmed(address indexed user, address indexed seller, uint256 amount);
    event disputeRaised(address indexed initiator);
    event disputeResolved(address indexed arbiter, address indexed recipeint, uint256 amount);
    event escrowCancellation(address indexed initiator);
    event deliveryTimeoutReached(address indexed buyer);

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_deliveryTimeout > 0, "Timeout must be greater than 0");
        buyer = msg.sender;
        seller = _seller;
        aribiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
        state = EscrowState.AWAITING_PAYMENT;
    }

    receive() external payable {
        revert ("Direct payments are not allowed");
    }
}