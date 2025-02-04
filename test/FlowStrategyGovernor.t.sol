pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./utils/BaseTest.t.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {console} from "forge-std/console.sol";

contract FlowStrategyGovernorTest is BaseTest {
    DutchAuction dutchAuction;

    uint64 defaultDuration = 1 days;
    uint128 defaultStartPrice = 10_000e6;
    uint128 defaultEndPrice = 3_000e6;
    uint128 defaultAmount = 100e18;

    function setUp() public virtual override {
        super.setUp();
        dutchAuction = new DutchAuction(address(flowStrategy), address(governor), address(usdcToken));
        vm.startPrank(address(governor));
        flowStrategy.grantRoles(address(dutchAuction), flowStrategy.MINTER_ROLE());
        dutchAuction.grantRoles(admin1.addr, dutchAuction.ADMIN_ROLE());
        dutchAuction.grantRoles(admin2.addr, dutchAuction.ADMIN_ROLE());
        vm.stopPrank();
    }

    function test_proposal_success() public {
        vm.startPrank(address(dutchAuction));
        flowStrategy.mint(alice, defaultAmount);
        flowStrategy.mint(bob, defaultAmount);
        flowStrategy.mint(charlie, defaultAmount);
        vm.stopPrank();
        vm.prank(alice);
        flowStrategy.delegate(alice);
        vm.prank(bob);
        flowStrategy.delegate(bob);
        vm.prank(charlie);
        flowStrategy.delegate(charlie);

        address[] memory targets = new address[](1);
        targets[0] = address(dutchAuction);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector, 0, defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount
        );
        string memory description = "test";

        uint256 proposalId = governor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.startPrank(charlie);
        vm.expectEmit(address(governor));
        emit IGovernor.ProposalCreated(
            proposalId,
            charlie,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            block.number + governor.votingDelay(),
            block.number + governor.votingPeriod() + governor.votingDelay(),
            description
        );
        governor.propose(targets, values, calldatas, description);
        vm.stopPrank();
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Pending), "proposal not pending");
        assertEq(governor.proposalNeedsQueuing(proposalId), false, "proposal needs queuing");
        assertEq(governor.hasVoted(proposalId, address(alice)), false, "alice has not voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), false, "bob has not voted");
        assertEq(governor.hasVoted(proposalId, address(charlie)), false, "charlie has not voted");

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(alice);
        governor.castVote(proposalId, 1);
        vm.prank(bob);
        governor.castVote(proposalId, 0);
        vm.prank(charlie);
        governor.castVote(proposalId, 1);

        assertEq(governor.hasVoted(proposalId, address(alice)), true, "alice has voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), true, "bob has voted");
        assertEq(governor.hasVoted(proposalId, address(charlie)), true, "charlie has voted");
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active), "proposal not active");
        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded), "proposal not succeeded");

        DutchAuction.Auction memory auction = DutchAuction.Auction({
            startTime: uint64(block.timestamp),
            duration: defaultDuration,
            startPrice: defaultStartPrice,
            endPrice: defaultEndPrice,
            amount: defaultAmount
        });
        vm.expectEmit();
        emit DutchAuction.AuctionStarted(auction);
        vm.expectEmit();
        emit IGovernor.ProposalExecuted(proposalId);
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
    }

    function test_proposal_didNotReachQuorum() public {
        vm.startPrank(address(dutchAuction));
        flowStrategy.mint(alice, defaultAmount * 97);
        flowStrategy.mint(bob, defaultAmount * 3);
        vm.stopPrank();
        vm.prank(alice);
        flowStrategy.delegate(alice);
        vm.prank(bob);
        flowStrategy.delegate(bob);

        address[] memory targets = new address[](1);
        targets[0] = address(dutchAuction);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector, 0, defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount
        );
        string memory description = "test";

        uint256 proposalId = governor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.startPrank(charlie);
        vm.expectEmit(address(governor));
        emit IGovernor.ProposalCreated(
            proposalId,
            charlie,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            block.number + governor.votingDelay(),
            block.number + governor.votingPeriod() + governor.votingDelay(),
            description
        );
        governor.propose(targets, values, calldatas, description);
        vm.stopPrank();
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Pending), "proposal not pending");
        assertEq(governor.proposalNeedsQueuing(proposalId), false, "proposal needs queuing");
        assertEq(governor.hasVoted(proposalId, address(alice)), false, "alice has not voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), false, "bob has not voted");
        assertEq(governor.hasVoted(proposalId, address(charlie)), false, "charlie has not voted");

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(bob);
        governor.castVote(proposalId, 1);

        assertEq(governor.hasVoted(proposalId, address(alice)), false, "alice has voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), true, "bob has voted");
        assertEq(governor.hasVoted(proposalId, address(charlie)), false, "charlie has voted");
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active), "proposal not active");
        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated), "proposal not defeated");

        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorUnexpectedProposalState.selector, proposalId, 3, 48));
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
    }

    function test_proposal_defeated() public {
        vm.startPrank(address(dutchAuction));
        flowStrategy.mint(alice, defaultAmount * 97);
        flowStrategy.mint(bob, defaultAmount * 3);
        vm.stopPrank();
        vm.prank(alice);
        flowStrategy.delegate(alice);
        vm.prank(bob);
        flowStrategy.delegate(bob);

        address[] memory targets = new address[](1);
        targets[0] = address(dutchAuction);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector, 0, defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount
        );
        string memory description = "test";

        uint256 proposalId = governor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        vm.startPrank(charlie);
        vm.expectEmit(address(governor));
        emit IGovernor.ProposalCreated(
            proposalId,
            charlie,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            block.number + governor.votingDelay(),
            block.number + governor.votingPeriod() + governor.votingDelay(),
            description
        );
        governor.propose(targets, values, calldatas, description);
        vm.stopPrank();
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Pending), "proposal not pending");
        assertEq(governor.proposalNeedsQueuing(proposalId), false, "proposal needs queuing");
        assertEq(governor.hasVoted(proposalId, address(alice)), false, "alice has not voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), false, "bob has not voted");

        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(alice);
        governor.castVote(proposalId, 0);

        assertEq(governor.hasVoted(proposalId, address(alice)), true, "alice has voted");
        assertEq(governor.hasVoted(proposalId, address(bob)), false, "bob has voted");
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active), "proposal not active");
        vm.roll(block.number + governor.votingPeriod() + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated), "proposal not defeated");

        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorUnexpectedProposalState.selector, proposalId, 3, 48));
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
    }
}
