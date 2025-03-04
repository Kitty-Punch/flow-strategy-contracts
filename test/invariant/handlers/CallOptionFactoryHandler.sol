// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CallOptionFactory} from "../../../src/options/CallOptionFactory.sol";
import {CallOption} from "../../../src/options/CallOption.sol";
import {IPremiumCalculator} from "../../../src/interfaces/options/IPremiumCalculator.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

contract CallOptionFactoryHandler is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    CallOptionFactory public factory;

    uint256 public latestOptionId;
    mapping(uint256 optionId => address option) public options;
    mapping(address paymentToken => uint256 totalPremiumPaid) public totalPremiumPaid;
    mapping(address paymentToken => uint256 totalStrikePaid) public totalStrikePaid;
    mapping(address user => uint256[] optionIds) public userOptionIds;
    EnumerableSet.AddressSet private _users;

    constructor(CallOptionFactory _factory) {
        factory = _factory;
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
        vm.startPrank(factory.governor());
        address option = factory.createCallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );
        vm.stopPrank();

        latestOptionId++;
        options[latestOptionId] = option;
        vm.label(option, string.concat("option_", vm.toString(latestOptionId)));

        return option;
    }

    function buyCallOption(
        uint128 _userPk,
        uint256 _optionId,
        uint256 _amount
    ) external returns (uint256 tokenId) {
        if (latestOptionId < 1) {
            return 0;
        }
        _optionId = bound(_optionId, 1, latestOptionId);
        address user = vm.addr(_userPk);

        CallOption option = CallOption(options[_optionId]);
        address paymentToken = option.paymentToken();
        uint256 strikePrice = option.strikePrice();
        uint256 expiration = option.expiration();
        _amount = bound(_amount, option.minAmount(), type(uint64).max);

        address premiumCalculator = option.premiumCalculator();
        uint256 premiumPaid = IPremiumCalculator(premiumCalculator).getPremium(_amount, strikePrice, expiration);

        deal(paymentToken, user, premiumPaid);

        vm.startPrank(user);
        IERC20(paymentToken).approve(address(option), premiumPaid);
        tokenId = option.buyCallOption(_amount);
        vm.stopPrank();

        totalPremiumPaid[paymentToken] += premiumPaid;
        userOptionIds[user].push(tokenId);
        if (!_users.contains(user)) {
            _users.add(user);
        }

        return tokenId;
    }

    function exerciseCallOption(uint256 _userIndex, uint256 _optionId, uint256 _optionTokenIndex) external returns (uint256 amountBought, uint256 totalStrikeCost){
        if (latestOptionId < 1) {
            return (0, 0);
        }
        if (_users.length() == 0) {
            return (0, 0);
        }
        _userIndex = bound(_userIndex, 0, _users.length() - 1);
        _optionId = bound(_optionId, 1, latestOptionId);

        CallOption option = CallOption(options[_optionId]);
        address user = _users.at(_userIndex);

        if (userOptionIds[user].length == 0) {
            return (0, 0);
        }
        uint256 strikePrice = option.strikePrice();
        _optionTokenIndex = bound(_optionTokenIndex, 0, userOptionIds[user].length - 1);
        uint256 optionTokenId = userOptionIds[user][_optionTokenIndex];
        uint256 amount = option.getOption(optionTokenId).amount;
        uint256 internalTotalStrikeCost = amount * strikePrice;
        address paymentToken = option.paymentToken();

        deal(paymentToken, user, totalStrikeCost);

        vm.startPrank(user);
        IERC20(paymentToken).approve(address(option), internalTotalStrikeCost);
        (amountBought, totalStrikeCost) = option.exerciseOption(optionTokenId);
        vm.stopPrank();
        require(totalStrikeCost == internalTotalStrikeCost, "Total strike cost mismatch");

        totalStrikePaid[paymentToken] += totalStrikeCost;
    }
}
