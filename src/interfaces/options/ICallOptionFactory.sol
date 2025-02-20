// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICallOption} from "./ICallOption.sol";
import {IPremiumCalculator} from "./IPremiumCalculator.sol";

interface ICallOptionFactory {
    function createCallOption(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) external returns (address);

    function underlyingToken() external view returns (address);

    function treasury() external view returns (address);

    function governor() external view returns (address);

    function getCallOptions() external view returns (address[] memory);

    function getTotalCallOptions() external view returns (uint256);

    function getCallOptionAt(uint256 _index) external view returns (address);

    function isCallOption(address _option) external view returns (bool);
}
