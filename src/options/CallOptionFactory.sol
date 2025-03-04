// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CallOption} from "./CallOption.sol";
import {ICallOptionFactory} from "../interfaces/options/ICallOptionFactory.sol";

contract CallOptionFactory is ICallOptionFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // The token that can be bought
    address public immutable underlyingToken;
    // The treasury address
    address public immutable treasury;
    // The governor address
    address public immutable governor;
    // The call options
    EnumerableSet.AddressSet private _callOptions;

    constructor(address _underlyingToken, address _treasury, address _governor) {
        require(_underlyingToken != address(0), "Underlying token cannot be 0");
        require(_treasury != address(0), "Treasury cannot be 0");
        require(_governor != address(0), "Governor cannot be 0");
        underlyingToken = _underlyingToken;
        treasury = _treasury;
        governor = _governor;
    }

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
    ) external returns (address) {
        require(msg.sender == governor, "Sender is not governor");
        require(_paymentToken != address(0), "Payment token address cannot be 0");
        require(_premiumCalculator != address(0), "Premium calculator address cannot be 0");
        require(_expiration > block.timestamp, "Expiration must be in the future");
        require(_strikePrice > 0, "Strike price must be greater than 0");

        CallOption callOption = new CallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );
        _callOptions.add(address(callOption));

        return address(callOption);
    }

    function getCallOptions() external view returns (address[] memory) {
        return _callOptions.values();
    }

    function getTotalCallOptions() external view returns (uint256) {
        return _callOptions.length();
    }

    function getCallOptionAt(uint256 _index) external view returns (address) {
        return _callOptions.at(_index);
    }

    function isCallOption(address _option) external view returns (bool) {
        return _callOptions.contains(_option);
    }
}
