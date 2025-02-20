// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {CallOption} from "../../src/options/CallOption.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockPremiumCalculator} from "../mocks/MockPremiumCalculator.sol";
import {CallOptionBaseTest} from "./CallOptionBase.t.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract CallOptionTest is CallOptionBaseTest {

    // Test constants
    string constant NAME = "Test Call Option";
    string constant SYMBOL = "TCO";
    string constant URI = "https://test.uri/";
    uint256 constant CAP = 1000;

    function setUp() public override {
        super.setUp();
    }

    function test_constructor_valid(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) public {
        vm.assume(bytes(_name).length > 0);
        vm.assume(bytes(_symbol).length > 0);
        vm.assume(bytes(_uri).length > 0);
        vm.assume(_premiumCalculator != address(0));
        vm.assume(_paymentToken != address(0));
        vm.assume(_cap > 0);
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);

        CallOption _callOption = new CallOption(
            _name, _symbol, _uri, _premiumCalculator, _paymentToken, _cap, _minAmount, _strikePrice, _expiration
        );

        assertEq(_callOption.name(), _name);
        assertEq(_callOption.symbol(), _symbol);
        assertEq(_callOption.baseURI(), _uri);
        assertEq(_callOption.premiumCalculator(), _premiumCalculator);
        assertEq(_callOption.paymentToken(), _paymentToken);
        assertEq(_callOption.minAmount(), _minAmount);
        assertEq(_callOption.strikePrice(), _strikePrice);
        assertEq(_callOption.expiration(), _expiration);
        assertEq(_callOption.factory(), address(this));
    }

    function test_constructor_zeroPremiumCalculator(uint256 _minAmount, uint256 _strikePrice, uint256 _expiration)
        public
    {
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);

        address _paymentToken = _createPaymentToken(6);

        vm.expectRevert("Premium calculator cannot be 0 address");
        new CallOption(NAME, SYMBOL, URI, address(0), _paymentToken, CAP, _minAmount, _strikePrice, _expiration);
    }

    function test_constructor_zeroPaymentToken(
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration,
        address _premiumCalculator
    ) public {
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration > block.timestamp);
        vm.assume(_premiumCalculator != address(0));

        vm.expectRevert("Payment token cannot be 0 address");
        new CallOption(NAME, SYMBOL, URI, _premiumCalculator, address(0), CAP, _minAmount, _strikePrice, _expiration);
    }

    function test_constructor_zeroStrikePrice(uint256 _minAmount, uint256 _expiration, address _premiumCalculator)
        public
    {
        vm.assume(_minAmount > 0);
        vm.assume(_expiration > block.timestamp);
        vm.assume(_premiumCalculator != address(0));
        address _paymentToken = _createPaymentToken(6);

        vm.expectRevert("Strike price must be positive");
        new CallOption(NAME, SYMBOL, URI, _premiumCalculator, _paymentToken, CAP, _minAmount, 0, _expiration);
    }

    function test_constructor_pastExpiration(
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration,
        address _premiumCalculator
    ) public {
        vm.assume(_minAmount > 0);
        vm.assume(_strikePrice > 0);
        vm.assume(_expiration <= block.timestamp);
        vm.assume(_premiumCalculator != address(0));
        address _paymentToken = _createPaymentToken(6);

        vm.expectRevert("Expiration must be in future");
        new CallOption(NAME, SYMBOL, URI, _premiumCalculator, _paymentToken, CAP, _minAmount, _strikePrice, _expiration);
    }

    function test_buyCallOption_valid(uint160 _userPk, uint256 _minAmount, uint256 _amount, uint256 premium) public {
        vm.assume(_userPk != 0);
        address _user = vm.addr(_userPk);
        vm.assume(_minAmount > 0);
        vm.assume(_minAmount < 1_000e18);
        vm.assume(_amount >= _minAmount);
        vm.assume(premium > 0 && premium < 1_000e18);
        vm.assume(premium < _minAmount);

        uint256 _strikePrice = 5e15;
        uint256 _expiration = block.timestamp + 1 days;
        CallOption _callOption = _createCallOption(_minAmount, _strikePrice, _expiration);
        MockPremiumCalculator _mockPremiumCalculator = MockPremiumCalculator(_callOption.premiumCalculator());
        _mockPremiumCalculator.setPremium(premium);

        IERC20 _paymentToken = IERC20(_callOption.paymentToken());
        deal(address(_paymentToken), _user, premium);
        
        vm.startPrank(_user);
        _paymentToken.approve(address(_callOption), premium);
        uint256 _optionId = _callOption.buyCallOption(_amount);

        vm.stopPrank();

        assertEq(_paymentToken.balanceOf(_user), 0, "User should have 0 balance");
        assertEq(_paymentToken.balanceOf(address(_callOption)), 0, "Call option should have 0 balance");
        assertEq(_paymentToken.balanceOf(_treasury()), premium, "Treasury should have premium");
        assertEq(_callOption.ownerOf(_optionId), _user, "User should be the owner of the option");
        assertEq(_callOption.totalSupply(), 1, "Total supply should be 1");
        assertEq(_callOption.getOption(_optionId).premiumPaid, premium, "Premium paid should be equal to premium");
        assertEq(_callOption.getOption(_optionId).amount, _amount, "Amount should be equal to amount");
        assertEq(_callOption.getOption(_optionId).exercised, false, "Option should not be exercised");
    }

    function test_buyCallOption_invalid_not_enough_premium(uint160 _userPk, uint256 _minAmount, uint256 _amount, uint256 premium, uint256 _premiumApproved) public {
        vm.assume(_userPk != 0);
        address _user = vm.addr(_userPk);
        vm.assume(_minAmount > 0);
        vm.assume(_minAmount < 1_000e18);
        vm.assume(_amount >= _minAmount);
        vm.assume(premium > 0 && premium < 1_000e18);
        vm.assume(premium < _minAmount);
        vm.assume(_premiumApproved > 0);
        vm.assume(_premiumApproved < premium);

        uint256 _strikePrice = 5e15;
        uint256 _expiration = block.timestamp + 1 days;
        CallOption _callOption = _createCallOption(_minAmount, _strikePrice, _expiration);
        MockPremiumCalculator _mockPremiumCalculator = MockPremiumCalculator(_callOption.premiumCalculator());
        _mockPremiumCalculator.setPremium(premium);

        IERC20 _paymentToken = IERC20(_callOption.paymentToken());
        deal(address(_paymentToken), _user, _premiumApproved);
        
        vm.startPrank(_user);
        _paymentToken.approve(address(_callOption), _premiumApproved);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(_callOption),
                _premiumApproved,
                premium
            )
        );
        _callOption.buyCallOption(_amount);

        vm.stopPrank();

        // assertEq(_paymentToken.balanceOf(_user), 0, "User should have 0 balance");
        // assertEq(_paymentToken.balanceOf(address(_callOption)), 0, "Call option should have 0 balance");
        // assertEq(_paymentToken.balanceOf(_treasury()), premium, "Treasury should have premium");
        // assertEq(_callOption.ownerOf(_optionId), _user, "User should be the owner of the option");
        // assertEq(_callOption.totalSupply(), 1, "Total supply should be 1");
        // assertEq(_callOption.getOption(_optionId).premiumPaid, premium, "Premium paid should be equal to premium");
        // assertEq(_callOption.getOption(_optionId).amount, _amount, "Amount should be equal to amount");
        // assertEq(_callOption.getOption(_optionId).exercised, false, "Option should not be exercised");
    }

    function test_buyCallOption_not_valid_less_than_min_amount(uint160 _userPk, uint256 _minAmount, uint256 _amount, uint256 premium) public {
        vm.assume(_userPk != 0);
        address _user = vm.addr(_userPk);
        vm.assume(_minAmount > 0);
        vm.assume(_minAmount < 1_000e18);
        vm.assume(_amount < _minAmount);
        vm.assume(premium > 0 && premium < 1_000e18);
        vm.assume(premium < _minAmount);

        uint256 _strikePrice = 5e15;
        uint256 _expiration = block.timestamp + 1 days;
        CallOption _callOption = _createCallOption(_minAmount, _strikePrice, _expiration);
        MockPremiumCalculator _mockPremiumCalculator = MockPremiumCalculator(_callOption.premiumCalculator());
        _mockPremiumCalculator.setPremium(premium);

        IERC20 _paymentToken = IERC20(_callOption.paymentToken());
        deal(address(_paymentToken), _user, premium);
        
        vm.startPrank(_user);
        _paymentToken.approve(address(_callOption), premium);
        vm.expectRevert("Amount must be gt min amount");
        _callOption.buyCallOption(_amount);

        vm.stopPrank();

        assertEq(_paymentToken.balanceOf(_user), premium, "User should have premium");
        assertEq(_paymentToken.balanceOf(address(_callOption)), 0, "Call option should have 0");
        assertEq(_paymentToken.balanceOf(_treasury()), 0, "Treasury should have 0");
        assertEq(_callOption.balanceOf(_user), 0, "User should have 0 balance");
        assertEq(_callOption.totalSupply(), 0, "Total supply should be 0");
    }

    function test_buyCallOption_not_valid_expired(uint160 _userPk, uint256 _minAmount, uint256 _amount, uint256 premium, uint64 _expirationOffset) public {
        vm.assume(_userPk != 0);
        address _user = vm.addr(_userPk);
        vm.assume(_minAmount > 0);
        vm.assume(_minAmount < 1_000e18);
        vm.assume(_amount >= _minAmount);
        vm.assume(premium > 0 && premium < 1_000e18);
        vm.assume(premium < _minAmount);
        vm.assume(_expirationOffset > 0);

        uint256 _strikePrice = 5e15;
        uint256 _expiration = block.timestamp + _expirationOffset;
        CallOption _callOption = _createCallOption(_minAmount, _strikePrice, _expiration);
        MockPremiumCalculator _mockPremiumCalculator = MockPremiumCalculator(_callOption.premiumCalculator());
        _mockPremiumCalculator.setPremium(premium);

        IERC20 _paymentToken = IERC20(_callOption.paymentToken());
        deal(address(_paymentToken), _user, premium);

        vm.warp(block.timestamp + _expirationOffset);
        
        vm.startPrank(_user);
        _paymentToken.approve(address(_callOption), premium);
        vm.expectRevert("Option expired");
        _callOption.buyCallOption(_amount);

        vm.stopPrank();

        assertEq(_paymentToken.balanceOf(_user), premium, "User should have premium");
        assertEq(_paymentToken.balanceOf(address(_callOption)), 0, "Call option should have 0 balance");
        assertEq(_paymentToken.balanceOf(_treasury()), 0, "Treasury should have 0");
        assertEq(_callOption.balanceOf(_user), 0, "User should have 0 balance");
        assertEq(_callOption.totalSupply(), 0, "Total supply should be 0");
    }
}
