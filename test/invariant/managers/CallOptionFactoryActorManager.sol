// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {CallOptionFactoryHandler} from "../handlers/CallOptionFactoryHandler.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {CallOption} from "../../../src/options/CallOption.sol";
import {IPremiumCalculator} from "../../../src/interfaces/options/IPremiumCalculator.sol";

contract CallOptionFactoryActorManager is Test {
    IPremiumCalculator public premiumCalculator;
    CallOptionFactoryHandler[] public handlers;

    CallOption[] public options;
    address[] public paymentTokens;
    uint256 public totalUnderlyingTokensSold;

    constructor(
        CallOptionFactoryHandler[] memory _handlers,
        IPremiumCalculator _premiumCalculator,
        address[] memory _paymentTokens
    ) {
        premiumCalculator = _premiumCalculator;
        for (uint256 i = 0; i < _handlers.length; i++) {
            handlers.push(_handlers[i]);
        }
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            paymentTokens.push(_paymentTokens[i]);
        }
    }

    function createCallOption(
        uint256 _handlerIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint8 _paymentTokenIndex,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint8 _expirationDays
    ) external {
        _strikePrice = bound(_strikePrice, 1e10, 1e18);
        _minAmount = bound(_minAmount, 1e10, type(uint64).max);
        _expirationDays = uint8(bound(uint256(_expirationDays), 1, 90)); // 90 days
        CallOptionFactoryHandler handler = boundHandler(_handlerIndex);
        address paymentToken = boundPaymentToken(_paymentTokenIndex);
        address option = handler.createCallOption(
            _name,
            _symbol,
            _uri,
            address(premiumCalculator),
            paymentToken,
            _cap,
            _minAmount,
            _strikePrice,
            block.timestamp + _expirationDays * 1 days
        );
        options.push(CallOption(option));
    }

    function exerciseCallOption(uint256 _handlerIndex, uint256 _userIndex, uint256 _optionId, uint256 _optionTokenIndex) external {
        CallOptionFactoryHandler handler = boundHandler(_handlerIndex);
        (uint256 amountBought, ) = handler.exerciseCallOption(_userIndex, _optionId, _optionTokenIndex);
        totalUnderlyingTokensSold += amountBought;
    }

    function buyCallOption(uint256 _handlerIndex, uint128 _userPk, uint256 _optionId, uint256 _amount) external {
        CallOptionFactoryHandler handler = boundHandler(_handlerIndex);
        handler.buyCallOption(_userPk, _optionId, _amount);
    }

    function advanceDays(uint8 _days) external {
        _days = uint8(bound(uint256(_days), 1, 30)); // 30 days
        vm.warp(block.timestamp + _days * 1 days);
    }

    function boundHandler(uint256 _handlerIndex) internal view returns (CallOptionFactoryHandler) {
        _handlerIndex = bound(_handlerIndex, 0, handlers.length - 1);
        return handlers[_handlerIndex];
    }

    function boundPaymentToken(uint256 _paymentTokenIndex) internal view returns (address) {
        _paymentTokenIndex = bound(_paymentTokenIndex, 0, paymentTokens.length - 1);
        return paymentTokens[_paymentTokenIndex];
    }

    function totalPremiumsPaid() external view returns (address[] memory, uint256[] memory) {
        address[] memory _paymentTokens = new address[](paymentTokens.length);
        uint256[] memory _premiumsPaid = new uint256[](paymentTokens.length);
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            for (uint256 j = 0; j < handlers.length; j++) {
                _paymentTokens[i] = paymentTokens[i];
                _premiumsPaid[i] += handlers[j].totalPremiumPaid(paymentTokens[i]);
            }
        }
        return (_paymentTokens, _premiumsPaid);
    }

    function totalStrikePaid() external view returns (address[] memory, uint256[] memory) {
        address[] memory _paymentTokens = new address[](paymentTokens.length);
        uint256[] memory _strikePaid = new uint256[](paymentTokens.length);
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            for (uint256 j = 0; j < handlers.length; j++) {
                _paymentTokens[i] = paymentTokens[i];
                _strikePaid[i] += handlers[j].totalStrikePaid(paymentTokens[i]);
            }
        }
        return (_paymentTokens, _strikePaid);
    }

    function totalPaid() external view returns (address[] memory, uint256[] memory) {
        address[] memory _paymentTokens = new address[](paymentTokens.length);
        uint256[] memory _totalPaid = new uint256[](paymentTokens.length);
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            _paymentTokens[i] = paymentTokens[i];
            for (uint256 j = 0; j < handlers.length; j++) {
                _totalPaid[i] += handlers[j].totalPremiumPaid(paymentTokens[i]);
                _totalPaid[i] += handlers[j].totalStrikePaid(paymentTokens[i]);
            }
        }
        return (_paymentTokens, _totalPaid);
    }
}
