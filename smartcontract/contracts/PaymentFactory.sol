// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ConditionalPayment} from "./ConditionalPayment.sol";

// PaymentFactory
// Factory for deploying ConditionalPayment contracts
// Creates and tracks all conditional payment instances
contract PaymentFactory {
    // Total number of payments created
    uint256 public totalPayments;

    // Mapping of payment ID to payment contract address
    mapping(uint256 => address) public payments;

    // Mapping of user address to their payment IDs
    mapping(address => uint256[]) public userPayments;

    // Available condition types
    enum ConditionType {
        TIMESTAMP,    // Execute at specific timestamp
        MANUAL,       // Execute upon manual approval
        RECURRING,    // Execute on interval
        ORACLE        // Execute based on oracle data (future)
    }

    // Emitted when a new payment is created
    event PaymentCreated(
        uint256 indexed paymentId,
        address indexed paymentAddress,
        address indexed sender,
        address recipient,
        uint256 amount,
        ConditionType conditionType,
        uint256 executeAt
    );

    // Emitted when a payment is executed
    event PaymentExecuted(
        uint256 indexed paymentId,
        address indexed paymentAddress,
        address recipient,
        uint256 amount
    );

    // Emitted when a payment is refunded
    event PaymentRefunded(
        uint256 indexed paymentId,
        address indexed paymentAddress,
        address sender,
        uint256 amount
    );

    // Create a new time-based conditional payment
    function createTimeBasedPayment(
        address recipient,
        uint256 executeAt
    ) external payable returns (address paymentAddress) {
        require(recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "Amount must be > 0");
        require(executeAt > block.timestamp, "Timestamp must be in future");
        require(executeAt <= block.timestamp + 365 days, "Too far in future");

        return _createPayment(
            recipient,
            ConditionType.TIMESTAMP,
            abi.encode(executeAt)
        );
    }

    // Create a new manual approval payment
    function createManualPayment(
        address recipient,
        address[] calldata approvers,
        uint256 requiredApprovals
    ) external payable returns (address paymentAddress) {
        require(recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "Amount must be > 0");
        require(approvers.length > 0, "Need approvers");
        require(requiredApprovals > 0 && requiredApprovals <= approvers.length, "Invalid threshold");

        return _createPayment(
            recipient,
            ConditionType.MANUAL,
            abi.encode(approvers, requiredApprovals)
        );
    }

    // Create a new recurring payment
    function createRecurringPayment(
        address recipient,
        uint256 startTime,
        uint256 interval,
        uint256 occurrences
    ) external payable returns (address paymentAddress) {
        require(recipient != address(0), "Invalid recipient");
        require(msg.value > 0, "Amount must be > 0");
        require(interval >= 1 days, "Interval too short");
        require(interval <= 365 days, "Interval too long");
        require(startTime >= block.timestamp, "Start time in past");

        return _createPayment(
            recipient,
            ConditionType.RECURRING,
            abi.encode(startTime, interval, occurrences)
        );
    }

    // Internal function to deploy a ConditionalPayment contract
    function _createPayment(
        address recipient,
        ConditionType conditionType,
        bytes memory conditionData
    ) internal returns (address) {
        totalPayments++;
        uint256 paymentId = totalPayments;

        ConditionalPayment payment = new ConditionalPayment{
            value: msg.value
        }(
            msg.sender,
            recipient,
            msg.value,
            uint8(conditionType),
            conditionData
        );

        address paymentAddress = address(payment);
        payments[paymentId] = paymentAddress;
        userPayments[msg.sender].push(paymentId);

        emit PaymentCreated(
            paymentId,
            paymentAddress,
            msg.sender,
            recipient,
            msg.value,
            conditionType,
            block.timestamp
        );

        return paymentAddress;
    }

    // Get payment address by ID
    function getPayment(uint256 paymentId) external view returns (address) {
        return payments[paymentId];
    }

    // Get all payment IDs for a user
    function getUserPaymentIds(address user) external view returns (uint256[] memory) {
        return userPayments[user];
    }

    // Get count of payments for a user
    function getUserPaymentCount(address user) external view returns (uint256) {
        return userPayments[user].length;
    }

    // Check if payment ID exists
    function paymentExists(uint256 paymentId) external view returns (bool) {
        return paymentId > 0 && paymentId <= totalPayments;
    }
}
