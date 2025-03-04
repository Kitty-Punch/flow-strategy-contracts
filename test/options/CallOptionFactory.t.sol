// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {CallOption} from "../../src/options/CallOption.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockPremiumCalculator} from "../mocks/MockPremiumCalculator.sol";
import {CallOptionFactory} from "../../src/options/CallOptionFactory.sol";
import {ICallOption} from "../../src/interfaces/options/ICallOption.sol";
import {CallOptionBaseTest} from "./CallOptionBase.t.sol";

contract CallOptionFactoryTest is CallOptionBaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_createCallOption_valid(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) external {
        vm.assume(bytes(_name).length > 0);
        vm.assume(bytes(_symbol).length > 0);
        vm.assume(bytes(_uri).length > 0);
        vm.assume(_premiumCalculator != address(0));
        vm.assume(_paymentToken != address(0));
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);

        vm.prank(factory.governor());
        address _callOption = factory.createCallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );

        assertEq(factory.getTotalCallOptions(), 1, "Call option count should be 1");

        ICallOption callOption = ICallOption(_callOption);
        assertEq(callOption.name(), _name, "Name should be equal");
        assertEq(callOption.symbol(), _symbol, "Symbol should be equal");
        assertEq(callOption.premiumCalculator(), _premiumCalculator, "Premium calculator should be equal");
        assertEq(callOption.paymentToken(), _paymentToken, "Payment token should be equal");
        assertEq(callOption.minAmount(), _minAmount, "Min amount should be equal");
        assertEq(callOption.strikePrice(), _strikePrice, "Strike price should be equal");
        assertEq(callOption.expiration(), _expiration, "Expiration should be equal");
    }

    function test_createCallOption_invalid_not_governor(
        address _notGovernor,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) external {
        vm.assume(bytes(_name).length > 0);
        vm.assume(bytes(_symbol).length > 0);
        vm.assume(bytes(_uri).length > 0);
        vm.assume(_premiumCalculator != address(0));
        vm.assume(_paymentToken != address(0));
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);
        vm.assume(_notGovernor != factory.governor());

        vm.prank(_notGovernor);
        vm.expectRevert("Sender is not governor");
        factory.createCallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );
    }

    function test_createCallOption_invalid_payment_token_zero_address(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) external {
        vm.assume(bytes(_name).length > 0);
        vm.assume(bytes(_symbol).length > 0);
        vm.assume(bytes(_uri).length > 0);
        vm.assume(_premiumCalculator != address(0));
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);
        address _paymentToken = address(0);

        vm.prank(factory.governor());
        vm.expectRevert("Payment token address cannot be 0");
        factory.createCallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );
    }
}
