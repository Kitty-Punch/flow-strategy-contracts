pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./utils/BaseTest.t.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {console} from "forge-std/console.sol";
import {Deposit} from "../src/Deposit.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DepositTest is BaseTest {

  DutchAuction dutchAuction;
  Deposit deposit;

  uint64 defaultDuration = 1 days;
  uint128 defaultStartPrice = 10_000e6;
  uint128 defaultEndPrice = 3_000e6;
  uint128 defaultAmount = 100e18;

  uint256 defaultConversionPremium = 0;
  uint256 defaultConversionRate = 30_000;
  uint256 defaultDepositCap = 10_000e18;

  Account signer;

  function setUp() public override virtual {
    super.setUp();
    dutchAuction = new DutchAuction(
      address(ethStrategy),
      address(governor),
      address(usdcToken)
    );
    signer = makeAccount("signer");
    vm.label(signer.addr, "signer");
    deposit = new Deposit(
      address(governor),
      address(ethStrategy),
      signer.addr,
      defaultConversionRate,
      defaultConversionPremium,
      defaultDepositCap,
      true
    );
    vm.startPrank(address(governor));
    ethStrategy.grantRoles(address(dutchAuction), ethStrategy.MINTER_ROLE());
    ethStrategy.grantRoles(address(deposit), ethStrategy.MINTER_ROLE());
    dutchAuction.grantRoles(admin1.addr, dutchAuction.ADMIN_ROLE());
    dutchAuction.grantRoles(admin2.addr, dutchAuction.ADMIN_ROLE());
    vm.stopPrank();
  }

  function test_deposit_success() public {
    uint256 depositAmount = 1e18;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectEmit();
    emit ERC20.Transfer(address(0), alice, depositAmount * deposit.CONVERSION_RATE());
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    uint256 conversionRate = deposit.CONVERSION_RATE();
    assertEq(ethStrategy.balanceOf(alice),  conversionRate * depositAmount, "balance of alice incorrect");
    assertEq(deposit.depositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), true, "alice hasn't redeemed");
    assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
  }

function test_deposit_2success_whiteListDisabled() public {
    deposit = new Deposit(
      address(governor),
      address(ethStrategy),
      signer.addr,
      defaultConversionRate,
      defaultConversionPremium,
      defaultDepositCap,
      false
    );
    vm.startPrank(address(governor));
    ethStrategy.grantRoles(address(deposit), ethStrategy.MINTER_ROLE());
    vm.stopPrank();
    uint256 depositAmount = 1e18;
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectEmit();
    emit ERC20.Transfer(address(0), alice, depositAmount * deposit.CONVERSION_RATE());
    deposit.deposit{value: depositAmount}(new bytes(0));
    vm.stopPrank();

    uint256 conversionRate = deposit.CONVERSION_RATE();
    assertEq(ethStrategy.balanceOf(alice),  conversionRate * depositAmount, "balance of alice incorrect");
    assertEq(deposit.depositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
    assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
  }

  function test_deposit_DepositCapExceeded() public {
    uint256 depositAmount = defaultDepositCap + 1;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.DepositCapExceeded.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    assertEq(deposit.depositCap(), defaultDepositCap, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
    assertEq(address(governor).balance, 0, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_AlreadyRedeemed() public {
    uint256 depositAmount = 1e18;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount * 2);
    vm.startPrank(alice);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    vm.startPrank(alice);
    vm.expectRevert(Deposit.AlreadyRedeemed.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    assertEq(deposit.depositCap(), defaultDepositCap - depositAmount, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), true, "alice has redeemed");
    assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), depositAmount * deposit.CONVERSION_RATE(), "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_DepositAmountTooLow() public {
    uint256 depositAmount = 1e18 - 1;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.DepositAmountTooLow.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    assertEq(deposit.depositCap(), defaultDepositCap, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
    assertEq(address(governor).balance, 0, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_InvalidSignature() public {
    uint256 depositAmount = 1e18;
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.InvalidSignature.selector);
    deposit.deposit{value: depositAmount}(new bytes(0));
    vm.stopPrank();

    assertEq(deposit.depositCap(), defaultDepositCap, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
    assertEq(address(governor).balance, 0, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_DepositAmountTooHigh() public {
    uint256 depositAmount = 100e18 + 1;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.DepositAmountTooHigh.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    assertEq(deposit.depositCap(), defaultDepositCap, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
    assertEq(address(governor).balance, 0, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_DepositFailed() public {
    uint256 depositAmount = 1e18;
    bytes memory signature = getSignature(alice);
    OwnerDepositRejector ownerDepositRejector = new OwnerDepositRejector();
    vm.startPrank(address(governor));
    deposit.transferOwnership(address(ownerDepositRejector));
    vm.stopPrank();
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.DepositFailed.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();


    assertEq(deposit.depositCap(), defaultDepositCap, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), false, "alice has redeemed");
    assertEq(address(governor).balance, 0, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), 0, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
  }

  function test_deposit_ReentrancyForbidden() public {
    ReentrantDeposit reentrantDeposit = new ReentrantDeposit(deposit);
    vm.prank(address(governor));
    deposit.transferOwnership(address(reentrantDeposit));
    uint256 depositAmount = 1e18;
    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectRevert(Deposit.DepositFailed.selector);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();
  }

  function test_deposit_InvalidConversionPremium() public {
    uint256 conversionPremium = 100_01;
    vm.expectRevert(Deposit.InvalidConversionPremium.selector);
    deposit = new Deposit(
      address(governor),
      address(ethStrategy),
      signer.addr,
      defaultConversionRate,
      conversionPremium,
      defaultDepositCap,
      true
    );
  }

  function test_setSigner_success() public {
    vm.startPrank(address(governor));
    deposit.setSigner(bob);
    vm.stopPrank();
    assertEq(deposit.signer(), bob, "signer incorrect");
  }

  function test_setSigner_Unauthorized() public {
    vm.expectRevert(Ownable.Unauthorized.selector);
    deposit.setSigner(bob);
    assertEq(deposit.signer(), signer.addr, "signer incorrect");
  }

  function test_receive_InvalidCall() public {
    vm.deal(alice, 1e18);
    vm.prank(alice);
    vm.expectRevert(Deposit.InvalidCall.selector);
    payable(address(deposit)).call{value: 1e18}("");
  }

  function getSignature(address _to) public view returns (bytes memory) {
    bytes32 hash = keccak256(abi.encodePacked(_to));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.key, hash);
    return abi.encodePacked(r, s, v);
  }
  
  function testFuzz_deposit(uint256 depositAmount, uint256 depositCap, uint256 conversionRate, uint256 conversionPremium) public {
    depositAmount = bound(depositAmount, 1e18, 100e18);
    depositCap = bound(depositCap, 1e18, 10_000e18);
    conversionPremium = bound(conversionPremium, 0, 100_00);
    conversionRate = bound(conversionRate, 1, defaultConversionRate);
    vm.assume(depositAmount <= depositCap);

    uint256 DENOMINATOR_BP = deposit.DENOMINATOR_BP();
    deposit = new Deposit(
      address(governor),
      address(ethStrategy),
      signer.addr,
      conversionRate,
      conversionPremium,
      depositCap,
      true
    );

    vm.startPrank(address(governor));
    ethStrategy.grantRoles(address(deposit), ethStrategy.MINTER_ROLE());
    vm.stopPrank();

    bytes memory signature = getSignature(alice);
    vm.deal(alice, depositAmount);
    vm.startPrank(alice);
    vm.expectEmit();
    emit ERC20.Transfer(address(0), alice, (depositAmount * deposit.CONVERSION_RATE() * (DENOMINATOR_BP - conversionPremium)) / DENOMINATOR_BP);
    deposit.deposit{value: depositAmount}(signature);
    vm.stopPrank();

    assertEq(deposit.depositCap(), depositCap - depositAmount, "deposit cap incorrect");
    assertEq(deposit.hasRedeemed(alice), true, "alice has redeemed");
    assertEq(address(governor).balance, depositAmount, "governor balance incorrect");
    assertEq(ethStrategy.balanceOf(alice), (depositAmount * deposit.CONVERSION_RATE() * (DENOMINATOR_BP - conversionPremium)) / DENOMINATOR_BP, "alice balance incorrect");
    assertEq(address(deposit).balance, 0, "deposit balance incorrect");
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
    deposit.deposit{value: msg.value}(new bytes(0));
  }
}