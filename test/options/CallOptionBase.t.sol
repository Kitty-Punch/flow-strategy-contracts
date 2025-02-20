// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {CallOption} from "../../src/options/CallOption.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockPremiumCalculator} from "../mocks/MockPremiumCalculator.sol";
import {CallOptionFactory} from "../../src/options/CallOptionFactory.sol";

abstract contract CallOptionBaseTest is Test {
    CallOptionFactory public factory;

    function setUp() public virtual {
        address treasury = makeAddr("treasury");
        address governor = makeAddr("governor");
        MockERC20 underlyingToken = new MockERC20("Underlying Token", "UT", 18);
        factory = new CallOptionFactory(address(underlyingToken), treasury, governor);
    }

    function _createCallOption(
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) internal returns (CallOption) {
        vm.assume(_premiumCalculator != address(0));
        vm.assume(_paymentToken != address(0));
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);

        string memory _name = "Test Call Option";
        string memory _symbol = "TCOT";
        string memory _uri = "https://test.uri/";

        vm.prank(factory.governor());
        address _callOption = factory.createCallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );

        return CallOption(_callOption);
    }

    function _createCallOption(
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) internal returns (CallOption) {
        address _premiumCalculator = address(new MockPremiumCalculator());
        return _createCallOption(_premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration);
    }

    function _createCallOption(uint256 _cap, uint256 _minAmount, uint256 _strikePrice, uint256 _expiration)
        internal
        returns (CallOption)
    {
        address _paymentToken = address(new MockERC20("Payment Token", "PT", 6));
        return _createCallOption(_paymentToken, _cap, _minAmount, _strikePrice, _expiration);
    }

    function _createCallOption(uint256 _minAmount, uint256 _strikePrice, uint256 _expiration)
        internal
        returns (CallOption)
    {
        uint256 _cap = 0;
        return _createCallOption(_cap, _minAmount, _strikePrice, _expiration);
    }

    function _createPaymentToken(uint8 _decimals) internal returns (address) {
        return address(new MockERC20("Payment Token", "PT", _decimals));
    }

    function _treasury() internal view returns (address) {
        return factory.treasury();
    }

    function _governor() internal view returns (address) {
        return factory.governor();
    }

    function _underlyingToken() internal view returns (address) {
        return factory.underlyingToken();
    }
}
