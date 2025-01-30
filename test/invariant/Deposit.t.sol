// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Deposit} from "../../src/Deposit.sol";
import {DepositHandler} from "./handlers/DepositHandler.sol";
import {DepositActorManager} from "./managers/DepositActorManager.sol";
import {FlowStrategy} from "../../src/FlowStrategy.sol";
import {FlowStrategyGovernor} from "../../src/FlowStrategyGovernor.sol";
import {AtmAuction} from "../../src/AtmAuction.sol";
import {BondAuction} from "../../src/BondAuction.sol";

contract DepositInvariantTest is Test {
    Deposit private deposit;
    DepositActorManager public manager;
    DepositHandler[] private handlers;
    FlowStrategyGovernor public governor;
    FlowStrategy public flowStrategy;
    uint256 public depositCap;
    uint256 public depositConversionRate;

    function setUp() external {
        address operator = address(0x123456789);
        uint256 quorumPercentage = 4;
        uint256 votingDelay = 7200;
        uint256 votingPeriod = 50400;
        uint256 proposalThreshold = 0;
        address usdc = address(0xd7d43ab7b365f0d0789aE83F4385fA710FfdC98F);
        depositConversionRate = 10000;
        uint256 depositConversionPremium = 0;
        depositCap = 5000000000000000000000000;
        bool whiteListEnabled = true;
        address lst = address(0x0);

        vm.startPrank(operator);
        flowStrategy = new FlowStrategy(operator);
        governor = new FlowStrategyGovernor(
            IVotes(address(flowStrategy)), quorumPercentage, votingDelay, votingPeriod, proposalThreshold
        );
        AtmAuction atmAuction = new AtmAuction(address(flowStrategy), address(governor), usdc);
        BondAuction bondAuction = new BondAuction(address(flowStrategy), address(governor), usdc);

        deposit = new Deposit(
            address(governor),
            address(flowStrategy),
            operator,
            depositConversionRate,
            depositConversionPremium,
            depositCap,
            whiteListEnabled
        );

        // deposit.addWhitelist(whitelist);

        flowStrategy.grantRoles(address(atmAuction), flowStrategy.MINTER_ROLE());
        flowStrategy.grantRoles(address(bondAuction), flowStrategy.MINTER_ROLE());
        flowStrategy.grantRoles(address(deposit), flowStrategy.MINTER_ROLE());
        flowStrategy.mint(operator, 1);
        flowStrategy.transferOwnership(address(governor));
        vm.stopPrank();

        // Create handlers
        for (uint256 i = 0; i < 10; ++i) {
            DepositHandler handler = new DepositHandler(deposit);
            handlers.push(handler);
            vm.label(address(handler), string.concat("handler_", vm.toString(i)));
        }

        // Create manager
        manager = new DepositActorManager(deposit, handlers);

        targetContract(address(manager));

        // Labels for debugging
        vm.label(address(manager), "manager");
        vm.label(address(deposit), "deposit");
        vm.label(address(flowStrategy), "flowStrategy");
        vm.label(address(governor), "governor");
        vm.label(address(atmAuction), "atmAuction");
        vm.label(address(bondAuction), "bondAuction");
        vm.label(address(operator), "operator");
    }

    function invariant_total_deposited_le_cap() external view {
        assertLe(manager.totalDeposited(), depositCap, "Total deposited should not exceed cap");
    }

    function invariant_total_deposited_eq_governor_balance() external view {
        assertEq(manager.totalDeposited(), address(governor).balance, "Total deposits should equal governor balance");
    }

    function invariant_deposit_contract_balance_zero() external view {
        assertEq(address(deposit).balance, 0, "Deposit contract balance should always be zero");
    }

    function invariant_conversion_rate_constant() external view {
        assertEq(deposit.CONVERSION_RATE(), depositConversionRate, "Conversion rate should remain constant");
    }
}
