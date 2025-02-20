// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IPremiumCalculator} from "../../interfaces/options/IPremiumCalculator.sol";

/**
 * @title LinearDecayPremiumCalculator
 * @notice Implements a linear decay premium calculator for FlowStrategy using USDF.
 * The premium is calculated using a linear theta decay model.
 */
contract LinearDecayPremiumCalculator is IPremiumCalculator {
    // Base premium rate in basis points (e.g., 500 = 5%), denominator is 10,000.
    uint256 public immutable basePremiumRateBps;

    /**
     * @param _basePremiumRateBps The base premium rate in basis points (e.g., 500 for 5%).
     */
    constructor(uint256 _basePremiumRateBps) {
        require(_basePremiumRateBps > 0, "Invalid base premium rate bps");

        basePremiumRateBps = _basePremiumRateBps;
    }

    /**
     * @notice Calculate the premium for a call option.
     * @param amount The amount of tokens the option will cover.
     * @param strikePrice The strike price per token.
     * @param expiration The UNIX timestamp when the option expires.
     *
     * The premium is calculated as:
     * premium = (amount * strikePrice * basePremiumRateBps * (expiration - block.timestamp)) / (10000 * 1 days)
     */
    function getPremium(uint256 amount, uint256 strikePrice, uint256 expiration) external view returns (uint256) {
        require(expiration > block.timestamp, "Expiration must be in the future");

        uint256 timeToExpiration = expiration - block.timestamp;
        uint256 premium =
            (amount * strikePrice * basePremiumRateBps * timeToExpiration) / (10000 * 1 days);

        return premium;
    }
}
