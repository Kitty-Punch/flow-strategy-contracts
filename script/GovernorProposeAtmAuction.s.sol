pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {GovernorProposeAuctionBaseScript} from "./GovernorProposeAuctionBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";

contract GovernorProposeAtmAuctionScript is GovernorProposeAuctionBaseScript {
    function _getAuctionProposalData(
        Environment environment,
        FlowStrategyGovernor governor,
        FlowStrategy /*flowStrategy*/
    ) internal view virtual override returns (AuctionProposalData memory proposalData) {
        if (environment == Environment.Undefined) {
            revert("Undefined environment");
        }

        if (environment == Environment.Testnet) {
            proposalData = AuctionProposalData({
                paymentToken: address(0xd7d43ab7b365f0d0789aE83F4385fA710FfdC98F),
                startTime: uint64(block.timestamp + governor.votingDelay() + governor.votingPeriod() + 2 minutes),
                duration: 15 hours,
                startPrice: 10e6,
                endPrice: 5e6,
                amount: 5_000e18,
                description: "Initial ATM auction.",
                depositCap: 5_000_000e18,
                depositConversionPremium: 0,
                depositConversionRate: 10,
                lst: address(0),
                whiteListEnabled: true
            });
        }

        if (environment == Environment.Mainnet) {
            proposalData = AuctionProposalData({
                paymentToken: address(0x0),
                startTime: uint64(0),
                duration: 0,
                startPrice: 0,
                endPrice: 0,
                amount: 0,
                description: "",
                depositCap: 0,
                depositConversionPremium: 0,
                depositConversionRate: 0,
                lst: address(0),
                whiteListEnabled: false
            });
        }
    }

    function _propose(
        FlowStrategyGovernor flowStrategyGovernor,
        FlowStrategy flowStrategy,
        AuctionProposalData memory proposalData
    ) internal virtual override returns (address auction, uint256 proposalId) {
        auction = _createAuction(flowStrategyGovernor, flowStrategy, proposalData);
        bytes[] memory callDatas = new bytes[](2);
        callDatas[0] = abi.encodeWithSelector(OwnableRoles.grantRoles.selector, auction, flowStrategy.MINTER_ROLE());
        callDatas[1] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector,
            proposalData.startTime,
            proposalData.duration,
            proposalData.startPrice,
            proposalData.endPrice,
            proposalData.amount
        );

        (uint256[] memory values, address[] memory targets) = _getValuesAndTargets(0, auction, address(flowStrategy));

        proposalId =
            flowStrategyGovernor.hashProposal(targets, values, callDatas, keccak256(bytes(proposalData.description)));

        flowStrategyGovernor.propose(targets, values, callDatas, proposalData.description);
    }

    function _createAuction(
        FlowStrategyGovernor flowStrategyGovernor,
        FlowStrategy flowStrategy,
        AuctionProposalData memory proposalData
    ) internal virtual override returns (address atmAuction) {
        atmAuction =
            address(new AtmAuction(address(flowStrategy), address(flowStrategyGovernor), proposalData.paymentToken));
    }
}
