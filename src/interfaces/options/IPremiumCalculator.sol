// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IPremiumCalculator {
    function getPremium(
        uint256 _amount,
        uint256 _strikePrice,
        uint256 _expiration
    ) external view returns (uint256);
}
