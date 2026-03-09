// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockVaultFactory {
    address public compoundAddress;
    address public aaveAddress;

    constructor(address _compoundAddress, address _aaveAddress) {
        compoundAddress = _compoundAddress;
        aaveAddress = _aaveAddress;
    }

    function getCompoundAddress() external view returns (address) {
        return compoundAddress;
    }

    function getAaveAddress() external view returns (address) {
        return aaveAddress;
    }

    function setCompoundAddress(address _compoundAddress) external {
        compoundAddress = _compoundAddress;
    }

    function setAaveAddress(address _aaveAddress) external {
        aaveAddress = _aaveAddress;
    }
}
