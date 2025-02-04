pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./utils/BaseTest.t.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {Deposit} from "../src/Deposit.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {AllowableAccounts} from "../src/AllowableAccounts.sol";

contract DepositTest is BaseTest {
    DutchAuction dutchAuction;
    Deposit deposit;

    uint64 defaultDuration = 1 days;
    uint128 defaultStartPrice = 10_000e6;
    uint128 defaultEndPrice = 3_000e6;
    uint128 defaultAmount = 100e18;

    uint256 defaultConversionPremium = 0;
    uint256 defaultConversionRate = 30_000;
    uint256 defaultDepositCap = 10_000_000e18;

    Account operator;

    function setUp() public virtual override {
        super.setUp();
        dutchAuction = new DutchAuction(address(ethStrategy), address(governor), address(usdcToken));
        operator = makeAccount("operator");
        vm.label(operator.addr, "operator");
        deposit = new Deposit(
            address(governor),
            address(ethStrategy),
            operator.addr,
            defaultConversionRate,
            defaultConversionPremium,
            defaultDepositCap,
            true
        );
        vm.startPrank(address(operator.addr));
        deposit.addWhitelist(_getWhitelistedAddresses());
        vm.stopPrank();

        vm.startPrank(address(governor));
        ethStrategy.grantRoles(address(dutchAuction), ethStrategy.MINTER_ROLE());
        ethStrategy.grantRoles(address(deposit), ethStrategy.MINTER_ROLE());
        dutchAuction.grantRoles(admin1.addr, dutchAuction.ADMIN_ROLE());
        dutchAuction.grantRoles(admin2.addr, dutchAuction.ADMIN_ROLE());
        vm.stopPrank();
    }

    function test_deposit_success() public {
        uint256 depositAmount = 1000e18;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectEmit();
        emit ERC20.Transfer(address(0), alice, depositAmount * deposit.CONVERSION_RATE());
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        uint256 conversionRate = deposit.CONVERSION_RATE();
        assertEq(ethStrategy.balanceOf(alice), conversionRate * depositAmount, "balance of alice incorrect");
        assertEq(deposit.getDepositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), true, "alice hasn't redeemed");
        assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
    }

    function test_deposit_success_whiteListDisabled() public {
        Deposit _deposit = new Deposit(
            address(governor),
            address(ethStrategy),
            operator.addr,
            defaultConversionRate,
            defaultConversionPremium,
            defaultDepositCap,
            false
        );
        vm.startPrank(address(governor));
        ethStrategy.grantRoles(address(_deposit), ethStrategy.MINTER_ROLE());
        vm.stopPrank();
        uint256 depositAmount = 1000e18;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectEmit();
        emit ERC20.Transfer(address(0), alice, depositAmount * _deposit.CONVERSION_RATE());
        _deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        uint256 conversionRate = _deposit.CONVERSION_RATE();
        assertEq(ethStrategy.balanceOf(alice), conversionRate * depositAmount, "balance of alice incorrect");
        assertEq(_deposit.getDepositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
        assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
    }

    function test_deposit_DepositCapExceeded() public {
        uint256 depositAmount = defaultDepositCap + 1;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectRevert(Deposit.DepositCapExceeded.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(deposit.getDepositCap(), defaultDepositCap, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
        assertEq(address(governor).balance, 0, "governor balance incorrect");
        assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
        assertEq(address(deposit).balance, 0, "deposit balance incorrect");
    }

    function test_deposit_AlreadyRedeemed() public {
        uint256 depositAmount = 1000e18;
        vm.deal(alice, depositAmount * 2);
        vm.startPrank(alice);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(Deposit.AlreadyRedeemed.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(deposit.getDepositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), true, "alice has redeemed");
        assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
        assertEq(ethStrategy.balanceOf(alice), depositAmount * deposit.CONVERSION_RATE(), "alice balance incorrect");
        assertEq(address(deposit).balance, 0, "deposit balance incorrect");
    }

    function test_deposit_DepositAmountTooLow() public {
        uint256 depositAmount = deposit.MIN_DEPOSIT() - 1;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectRevert(Deposit.DepositAmountTooLow.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(deposit.getDepositCap(), defaultDepositCap, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
        assertEq(address(governor).balance, 0, "governor balance incorrect");
        assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
        assertEq(address(deposit).balance, 0, "deposit balance incorrect");
    }

    function test_deposit_DepositAmountTooHigh() public {
        uint256 depositAmount = deposit.MAX_DEPOSIT() + 1;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectRevert(Deposit.DepositAmountTooHigh.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(deposit.getDepositCap(), defaultDepositCap, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
        assertEq(address(governor).balance, 0, "governor balance incorrect");
        assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
        assertEq(address(deposit).balance, 0, "deposit balance incorrect");
    }

    function test_deposit_DepositFailed() public {
        uint256 depositAmount = 1000e18;
        OwnerDepositRejector ownerDepositRejector = new OwnerDepositRejector();
        vm.startPrank(address(governor));
        deposit.transferOwnership(address(ownerDepositRejector));
        vm.stopPrank();
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectRevert(Deposit.DepositFailed.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(deposit.getDepositCap(), defaultDepositCap, "deposit cap incorrect");
        assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
        assertEq(address(governor).balance, 0, "governor balance incorrect");
        assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
        assertEq(address(deposit).balance, 0, "deposit balance incorrect");
    }

    function test_deposit_ReentrancyForbidden() public {
        ReentrantDeposit reentrantDeposit = new ReentrantDeposit(deposit);
        vm.prank(address(governor));
        deposit.transferOwnership(address(reentrantDeposit));
        uint256 depositAmount = 1000e18;
        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectRevert(Deposit.DepositFailed.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();
    }

    function test_deposit_InvalidConversionPremium() public {
        uint256 conversionPremium = 100_01;
        vm.expectRevert(Deposit.InvalidConversionPremium.selector);
        new Deposit(
            address(governor),
            address(ethStrategy),
            operator.addr,
            defaultConversionRate,
            conversionPremium,
            defaultDepositCap,
            true
        );
    }

    function test_setOperator_success() public {
        vm.startPrank(address(operator.addr));
        deposit.setOperator(bob);
        vm.stopPrank();
        assertEq(deposit.operator(), bob, "operator incorrect");
    }

    function test_setOperator_Unauthorized() public {
        vm.expectRevert("Caller is not an operator");
        deposit.setOperator(bob);
        assertEq(deposit.operator(), operator.addr, "operator incorrect");
    }

    function test_receive_InvalidCall() public {
        vm.deal(alice, 1e18);
        vm.prank(alice);
        vm.expectRevert(Deposit.InvalidCall.selector);
        payable(address(deposit)).call{value: 1e18}("");
    }

    function testFuzz_deposit(
        uint256 depositAmount,
        uint256 depositCap,
        uint256 conversionRate,
        uint256 conversionPremium
    ) public {
        depositAmount = bound(depositAmount, 1000e18, 5_000_000e18);
        depositCap = bound(depositCap, 1000e18, 5_000_000e18);
        conversionPremium = bound(conversionPremium, 0, 100_00);
        conversionRate = bound(conversionRate, 1, defaultConversionRate);
        vm.assume(depositAmount <= depositCap);

        uint256 DENOMINATOR_BP = deposit.DENOMINATOR_BP();
        Deposit _deposit = new Deposit(
            address(governor), address(ethStrategy), operator.addr, conversionRate, conversionPremium, depositCap, true
        );
        vm.startPrank(address(operator.addr));
        _deposit.addWhitelist(_getWhitelistedAddresses());
        vm.stopPrank();

        vm.startPrank(address(governor));
        ethStrategy.grantRoles(address(_deposit), ethStrategy.MINTER_ROLE());
        vm.stopPrank();

        vm.deal(alice, depositAmount);
        vm.startPrank(alice);
        vm.expectEmit();
        emit ERC20.Transfer(
            address(0),
            alice,
            (depositAmount * _deposit.CONVERSION_RATE() * (DENOMINATOR_BP - conversionPremium)) / DENOMINATOR_BP
        );
        _deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        assertEq(_deposit.getDepositCap(), depositCap - depositAmount, "deposit cap incorrect");
        assertEq(_deposit.hasRedeemed(alice), true, "alice has redeemed");
        assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
        assertEq(
            ethStrategy.balanceOf(alice),
            (depositAmount * _deposit.CONVERSION_RATE() * (DENOMINATOR_BP - conversionPremium)) / DENOMINATOR_BP,
            "alice balance incorrect"
        );
        assertEq(address(_deposit).balance, 0, "deposit balance incorrect");
    }

    function test_addWhitelist_success() public {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x11);
        accounts[1] = address(0x22);

        vm.startPrank(operator.addr);
        vm.expectEmit(true, false, false, true);
        emit AllowableAccounts.WhitelistedAdded(accounts);
        deposit.addWhitelist(accounts);
        vm.stopPrank();

        assertTrue(deposit.isWhitelisted(address(0x11)), "First account not whitelisted");
        assertTrue(deposit.isWhitelisted(address(0x22)), "Second account not whitelisted");
    }

    function test_addWhitelist_unauthorized() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(0x11);

        vm.expectRevert("Caller is not an operator");
        deposit.addWhitelist(accounts);

        assertFalse(deposit.isWhitelisted(address(0x11)), "Account should not be whitelisted");
    }

    function test_addWhitelist_emptyArray() public {
        address[] memory accounts = new address[](0);

        vm.startPrank(operator.addr);
        vm.expectRevert(AllowableAccounts.NoAccountsToAdd.selector);
        deposit.addWhitelist(accounts);
        vm.stopPrank();
    }

    function test_addWhitelist_zeroAddress() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(0);

        vm.startPrank(operator.addr);
        vm.expectRevert(abi.encodeWithSelector(AllowableAccounts.InvalidAccount.selector, accounts[0]));
        deposit.addWhitelist(accounts);
        vm.stopPrank();
    }

    function test_addWhitelist_duplicateAddress() public {
        // First add an address
        address[] memory accounts1 = new address[](1);
        accounts1[0] = address(0x11);

        vm.startPrank(operator.addr);
        deposit.addWhitelist(accounts1);

        // Try to add the same address again
        vm.expectRevert(abi.encodeWithSelector(AllowableAccounts.AccountAlreadyAdded.selector, accounts1[0]));
        deposit.addWhitelist(accounts1);
        vm.stopPrank();
    }

    function test_addWhitelist_multipleAccounts() public {
        address[] memory accounts = new address[](3);
        accounts[0] = address(0x11);
        accounts[1] = address(0x22);
        accounts[2] = address(0x33);

        vm.startPrank(operator.addr);
        deposit.addWhitelist(accounts);
        vm.stopPrank();

        address[] memory whitelist = deposit.getWhitelist();
        assertEq(whitelist.length, 6, "Whitelist length incorrect"); // 3 accounts + 3 whitelisted addresses from setUp
        assertTrue(deposit.isWhitelisted(address(0x11)), "First account not whitelisted");
        assertTrue(deposit.isWhitelisted(address(0x22)), "Second account not whitelisted");
        assertTrue(deposit.isWhitelisted(address(0x33)), "Third account not whitelisted");
    }

    function test_removeWhitelist_success() public {
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x11);
        accounts[1] = address(0x22);

        vm.startPrank(operator.addr);
        deposit.addWhitelist(accounts);

        vm.expectEmit(true, false, false, true);
        emit AllowableAccounts.WhitelistedRemoved(accounts);
        deposit.removeWhitelist(accounts);
        vm.stopPrank();

        assertFalse(deposit.isWhitelisted(address(0x11)), "First account still whitelisted");
        assertFalse(deposit.isWhitelisted(address(0x22)), "Second account still whitelisted");
    }

    function test_removeWhitelist_unauthorized() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(0x11);

        vm.expectRevert("Caller is not an operator");
        deposit.removeWhitelist(accounts);
    }

    function test_removeWhitelist_emptyArray() public {
        address[] memory accounts = new address[](0);

        vm.startPrank(operator.addr);
        vm.expectRevert(AllowableAccounts.NoAccountsToRemove.selector);
        deposit.removeWhitelist(accounts);
        vm.stopPrank();
    }

    function test_removeWhitelist_accountNotFound() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(0x11);

        vm.startPrank(operator.addr);
        vm.expectRevert(abi.encodeWithSelector(AllowableAccounts.AccountNotFound.selector, accounts[0]));
        deposit.removeWhitelist(accounts);
        vm.stopPrank();
    }

    function test_deposit_notWhitelisted() public {
        uint256 depositAmount = 1000e18;
        address nonWhitelisted = address(0x9999);
        vm.deal(nonWhitelisted, depositAmount);

        vm.startPrank(nonWhitelisted);
        vm.expectRevert(Deposit.NotWhitelisted.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();
    }

    function test_getWhitelist() public {
        // Add some addresses to whitelist
        address[] memory accounts = new address[](2);
        accounts[0] = address(0x11);
        accounts[1] = address(0x22);

        vm.startPrank(operator.addr);
        deposit.addWhitelist(accounts);
        vm.stopPrank();

        // Get whitelist and verify
        address[] memory whitelist = deposit.getWhitelist();
        assertEq(whitelist.length, 5, "Whitelist length incorrect"); // 2 new accounts + 3 from setUp

        bool found1 = false;
        bool found2 = false;
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == address(0x11)) found1 = true;
            if (whitelist[i] == address(0x22)) found2 = true;
        }
        assertTrue(found1, "First account not in whitelist");
        assertTrue(found2, "Second account not in whitelist");
    }

    function test_removeWhitelist_multipleAccounts() public {
        // First add some addresses
        address[] memory accounts = new address[](3);
        accounts[0] = address(0x11);
        accounts[1] = address(0x22);
        accounts[2] = address(0x33);

        vm.startPrank(operator.addr);
        deposit.addWhitelist(accounts);

        // Remove them
        deposit.removeWhitelist(accounts);
        vm.stopPrank();

        address[] memory whitelist = deposit.getWhitelist();
        assertEq(whitelist.length, 3, "Whitelist length incorrect"); // Only the 3 from setUp remain
        assertFalse(deposit.isWhitelisted(address(0x11)), "First account still whitelisted");
        assertFalse(deposit.isWhitelisted(address(0x22)), "Second account still whitelisted");
        assertFalse(deposit.isWhitelisted(address(0x33)), "Third account still whitelisted");
    }

    function test_setWhiteListEnabled_success() public {
        vm.startPrank(operator.addr);

        // Test disabling whitelist
        vm.expectEmit(true, false, false, true);
        emit Deposit.WhiteListEnabledSet(false);
        deposit.setWhiteListEnabled(false);
        assertFalse(deposit.whiteListEnabled(), "Whitelist should be disabled");

        // Test enabling whitelist
        vm.expectEmit(true, false, false, true);
        emit Deposit.WhiteListEnabledSet(true);
        deposit.setWhiteListEnabled(true);
        assertTrue(deposit.whiteListEnabled(), "Whitelist should be enabled");
        vm.stopPrank();
    }

    function test_setWhiteListEnabled_unauthorized() public {
        vm.expectRevert("Caller is not an operator");
        deposit.setWhiteListEnabled(false);

        assertTrue(deposit.whiteListEnabled(), "Whitelist state should not change");
    }

    function test_deposit_whitelistToggle() public {
        uint256 depositAmount = 1000e18;
        address nonWhitelisted = address(0x9999);
        vm.deal(nonWhitelisted, depositAmount);

        // First verify deposit fails when whitelist is enabled
        vm.startPrank(nonWhitelisted);
        vm.expectRevert(Deposit.NotWhitelisted.selector);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        // Disable whitelist
        vm.startPrank(operator.addr);
        deposit.setWhiteListEnabled(false);
        vm.stopPrank();

        // Now deposit should succeed
        vm.startPrank(nonWhitelisted);
        deposit.deposit{value: depositAmount}();
        vm.stopPrank();

        uint256 conversionRate = deposit.CONVERSION_RATE();
        assertEq(
            ethStrategy.balanceOf(nonWhitelisted), conversionRate * depositAmount, "Balance incorrect after deposit"
        );
    }
}

contract OwnerDepositRejector {
    error Rejected();

    fallback() external payable {
        revert Rejected();
    }
}

contract ReentrantDeposit {
    Deposit deposit;

    constructor(Deposit _deposit) {
        deposit = _deposit;
    }

    fallback() external payable {
        deposit.deposit{value: msg.value}();
    }
}
