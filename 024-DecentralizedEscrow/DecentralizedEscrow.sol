// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a secure system for holding funds until conditions are met. You'll learn how to manage payments and handle disputes. 
    It's like a digital middleman for secure transactions, demonstrating secure conditional payments.
    
    -------------------------------------------------------------------------------------------------------------------------------------

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
    address public immutable arbiter; // trustted 3rd party that handles dispute

    EscrowState public eState;

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
        arbiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
        eState = EscrowState.AWAITING_PAYMENT;
    }

    // this receive funciton recieves ETH to contract. In here, we will reject the ETH without handling it.
    receive() external payable {
        revert ("Direct payments are not allowed");
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit.");
        require(eState == EscrowState.AWAITING_PAYMENT, "Already paid");
        require(msg.value > 0, "Amount must be greater than 0");
        amount = msg.value;
        eState = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;
        emit PaymentDesposited(buyer, msg.value);
    }

    function confirmedDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm.");
        require(eState == EscrowState.AWAITING_DELIVERY, "Not in delivery");
        eState = EscrowState.COMPLETE;
        (bool success,) = (msg.sender).call{value: amount}("");
        require(success, "Failed to transfer ETH");
        emit deliveryConfirmed(buyer, seller, amount);
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(eState == EscrowState.AWAITING_DELIVERY, "Cannot dispute");
        eState = EscrowState.DISPUTED;
        emit disputeRaised(msg.sender);
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter, "Only arbiter can resolve");
        require(eState == EscrowState.DISPUTED, "No dispute to resolve");
        if (_releaseToSeller) {
            (bool success, ) = (seller).call{value: amount}("");
            require(success, "Failed to send ETH to seller");
            emit disputeResolved(arbiter, seller, amount);
        } else {
            (bool success, ) = (buyer).call{value: amount}("");
            require(success, "Failed to send ETH to buyer");
            emit disputeResolved(arbiter, buyer, amount);
        }
    }

    function cancelAfterTimeout() external {
        require(msg.sender == buyer, "Only buyer can trigger after timeout");
        require(eState == EscrowState.AWAITING_DELIVERY, "Cannot cancel in delivery");
        require(block.timestamp >= depositTime + deliveryTimeout, "Timeout not reached");

        eState = EscrowState.CANCELLED;
        (bool success, ) = (buyer).call{value: amount}("");
        require(success, "Failed to send ETH to buyer");
        emit escrowCancellation(buyer);
        emit deliveryTimeoutReached(buyer);
    }

    function cancelMutual() external {
        require(msg.sender == buyer || msg.sender == seller, "Not authorized");
        require(eState == EscrowState.AWAITING_DELIVERY || eState == EscrowState.AWAITING_PAYMENT, "Can't cancel now");
        EscrowState previousState = eState;
        eState = EscrowState.CANCELLED; 

        if (previousState == EscrowState.AWAITING_DELIVERY) {
            (bool success, ) = (buyer).call{value: amount}("");
            require(success, "Failed to send ETH to buyer");
        }
        emit escrowCancellation(msg.sender);
    }

    function getLeftTime() external view returns(uint256) {
        if (eState != EscrowState.AWAITING_DELIVERY) return 0;
        if (block.timestamp >= depositTime + deliveryTimeout) return 0;
        return (depositTime + deliveryTimeout) - block.timestamp;
    }
}