pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {GovernorProposeAtmAuctionScript} from "./GovernorProposeAtmAuction.s.sol";

contract GovernorProposeBondAuctionScript is GovernorProposeAtmAuctionScript {
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
                // duration: 6 hours,
                duration: 10 minutes,
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

    function _createAuction(
        FlowStrategyGovernor flowStrategyGovernor,
        FlowStrategy flowStrategy,
        AuctionProposalData memory proposalData
    ) internal virtual override returns (address auction) {
        auction =
            address(new BondAuction(address(flowStrategy), address(flowStrategyGovernor), proposalData.paymentToken));
    }
}
