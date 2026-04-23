// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ConditionalPayment
// Escrow contract for conditional payments
// Holds funds in escrow and executes when conditions are met
contract ConditionalPayment {
    address public immutable sender;
    address public immutable recipient;
    uint256 public immutable amount;
    uint256 public immutable createdAt;

    enum ConditionType {
        TIMESTAMP,
        MANUAL,
        RECURRING,
        ORACLE
    }

    ConditionType public immutable conditionType;

    bool public executed;
    bool public refunded;

    // Condition data (packed for gas efficiency)
    uint256 public executeAt;      // For TIMESTAMP
    uint256 public startTime;      // For RECURRING
    uint256 public interval;       // For RECURRING
    uint256 public occurrences;    // For RECURRING
    uint256 public executedCount;  // For RECURRING

    // Manual approval tracking
    mapping(address => bool) public approvedBy;
    address[] public approvers;
    uint256 public requiredApprovals;

    uint256 public constant REFUND_TIMEOUT = 30 days;

    // Emitted when a payment is executed
    event PaymentExecuted(address indexed paymentAddress, address recipient, uint256 amount);

    // Emitted when a payment is refunded
    event PaymentRefunded(address indexed paymentAddress, address sender, uint256 amount);

    // Emitted when a manual payment is approved
    event ManualApproval(address indexed approver, address indexed paymentAddress);

    constructor(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint8 _conditionType,
        bytes memory _conditionData
    ) payable {
        require(_sender != address(0), "Invalid sender");
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be > 0");
        require(msg.value == _amount, "Value mismatch");
        require(_conditionType <= uint8(ConditionType.ORACLE), "Invalid condition type");

        sender = _sender;
        recipient = _recipient;
        amount = _amount;
        createdAt = block.timestamp;
        conditionType = ConditionType(_conditionType);

        _decodeConditionData(_conditionData);
    }

    function _decodeConditionData(bytes memory _conditionData) internal {
        if (conditionType == ConditionType.TIMESTAMP) {
            executeAt = abi.decode(_conditionData, (uint256));
            require(executeAt > block.timestamp, "Timestamp must be future");
            require(executeAt <= block.timestamp + 365 days, "Too far future");
        } else if (conditionType == ConditionType.MANUAL) {
            (address[] memory _approvers, uint256 _required) = abi.decode(
                _conditionData,
                (address[], uint256)
            );
            require(_approvers.length > 0, "Need approvers");
            require(_required > 0 && _required <= _approvers.length, "Invalid threshold");
            approvers = _approvers;
            requiredApprovals = _required;
        } else if (conditionType == ConditionType.RECURRING) {
            (uint256 _start, uint256 _interval, uint256 _occurrences) = abi.decode(
                _conditionData,
                (uint256, uint256, uint256)
            );
            require(_start >= block.timestamp, "Start in past");
            require(_interval >= 1 days && _interval <= 365 days, "Invalid interval");
            startTime = _start;
            interval = _interval;
            occurrences = _occurrences;
            executedCount = 0;
        }
    }

    function execute() external {
        require(!executed, "Already executed");
        require(!refunded, "Already refunded");
        require(_checkCondition(), "Condition not met");

        executed = true;

        if (conditionType == ConditionType.RECURRING) {
            executedCount++;
            if (occurrences == 0 || executedCount < occurrences) {
                executed = false;
                startTime += interval;
            }
        }

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        emit PaymentExecuted(address(this), recipient, amount);
    }

    function refund() external {
        require(!executed, "Already executed");
        require(!refunded, "Already refunded");
        require(
            msg.sender == sender ||
            (conditionType == ConditionType.TIMESTAMP && block.timestamp > createdAt + REFUND_TIMEOUT) ||
            (conditionType == ConditionType.MANUAL && _isRefundTimeElapsed()),
            "Refund not available"
        );
        refunded = true;
        (bool success, ) = sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit PaymentRefunded(address(this), sender, amount);
    }

    function approveManual() external {
        require(conditionType == ConditionType.MANUAL, "Not manual payment");
        require(!executed, "Already executed");
        require(!refunded, "Already refunded");
        require(_isApprover(msg.sender), "Not an approver");
        require(!approvedBy[msg.sender], "Already approved");
        approvedBy[msg.sender] = true;
        emit ManualApproval(msg.sender, address(this));
    }

    function _checkCondition() internal view returns (bool) {
        if (conditionType == ConditionType.TIMESTAMP) {
            return block.timestamp >= executeAt;
        } else if (conditionType == ConditionType.MANUAL) {
            return _getApprovalCount() >= requiredApprovals;
        } else if (conditionType == ConditionType.RECURRING) {
            return block.timestamp >= startTime &&
                   (occurrences == 0 || executedCount < occurrences);
        }
        return false;
    }

    function _isRefundTimeElapsed() internal view returns (bool) {
        return block.timestamp > createdAt + 7 days;
    }

    function _getApprovalCount() internal view returns (uint256) {
        uint256 count;
        for (uint256 i; i < approvers.length; i++) {
            if (approvedBy[approvers[i]]) count++;
        }
        return count;
    }

    function _isApprover(address _addr) internal view returns (bool) {
        for (uint256 i; i < approvers.length; i++) {
            if (approvers[i] == _addr) return true;
        }
        return false;
    }

    function checkCondition() external view returns (bool) {
        return _checkCondition();
    }

    function getApprovalCount() external view returns (uint256) {
        return _getApprovalCount();
    }

    function getStatus() external view returns (
        address senderAddr,
        address recipientAddr,
        uint256 amount_,
        bool executed_,
        bool refunded_,
        uint256 remainingTime
    ) {
        senderAddr = sender;
        recipientAddr = recipient;
        amount_ = amount;
        executed_ = executed;
        refunded_ = refunded;
        if (conditionType == ConditionType.TIMESTAMP && !executed) {
            remainingTime = executeAt > block.timestamp ? executeAt - block.timestamp : 0;
        }
    }

    function getRecurringInfo() external view returns (
        uint256 nextExecution,
        uint256 remainingOccurrences
    ) {
        if (conditionType == ConditionType.RECURRING) {
            nextExecution = startTime;
            remainingOccurrences = occurrences == 0 ? type(uint256).max : occurrences - executedCount;
        }
    }

    function getApprovers() external view returns (address[] memory) {
        return approvers;
    }

    receive() external payable {
        revert("Use create functions");
    }
}
