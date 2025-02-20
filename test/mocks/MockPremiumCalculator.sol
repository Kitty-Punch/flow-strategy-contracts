// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPremiumCalculator} from "../../src/interfaces/options/IPremiumCalculator.sol";

contract MockPremiumCalculator is IPremiumCalculator {
    uint256 private _premium;

    function setPremium(uint256 premium) external {
        _premium = premium;
    }

    function getPremium(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256) {
        return _premium;
    }
} 