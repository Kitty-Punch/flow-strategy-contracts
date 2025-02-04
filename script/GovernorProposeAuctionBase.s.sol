pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";

abstract contract GovernorProposeAuctionBaseScript is ScriptBase {
    struct AuctionProposalData {
        address paymentToken;
        uint64 startTime;
        uint64 duration;
        uint128 startPrice;
        uint128 endPrice;
        uint128 amount;
        string description;
        uint256 depositCap;
        uint256 depositConversionPremium;
        uint256 depositConversionRate;
        address lst;
        bool whiteListEnabled;
    }

    mapping(uint256 => string) public getProposalState;

    constructor() {
        getProposalState[0] = "Pending";
        getProposalState[1] = "Active";
        getProposalState[2] = "Canceled";
        getProposalState[3] = "Defeated";
        getProposalState[4] = "Succeeded";
        getProposalState[5] = "Queued";
        getProposalState[6] = "Expired";
        getProposalState[7] = "Executed";
    }

    function _getAuctionProposalData(Environment environment, FlowStrategyGovernor governor, FlowStrategy flowStrategy)
        internal
        view
        virtual
        returns (AuctionProposalData memory proposalData);

    function _printProposalData(AuctionProposalData memory proposalData) internal pure {
        console2.log(
            "\n\n-------------------------------------------- Proposal Data --------------------------------------------"
        );
        console2.log("Payment token:                ", proposalData.paymentToken);
        console2.log("Start time:                   ", proposalData.startTime);
        console2.log("Duration:                     ", proposalData.duration);
        console2.log("Start price:                  ", proposalData.startPrice);
        console2.log("End price:                    ", proposalData.endPrice);
        console2.log("Amount:                       ", proposalData.amount);
        console2.log("Description:                  ", proposalData.description);
        console2.log("Deposit cap:                  ", proposalData.depositCap);
        console2.log("Deposit conversion premium:   ", proposalData.depositConversionPremium);
        console2.log("Deposit conversion rate:      ", proposalData.depositConversionRate);
        console2.log("LST:                          ", proposalData.lst);
        console2.log("White list enabled:           ", proposalData.whiteListEnabled);
        console2.log(
            "------------------------------------------------------------------------------------------------------------\n\n"
        );
    }

    function run() public {
        Environment environment = Environment.Testnet;
        DeployedConfig memory config = _parseDeployedConfig("testnet");
        FlowStrategyGovernor flowStrategyGovernor = FlowStrategyGovernor(payable(config.FlowStrategyGovernor));
        FlowStrategy flowStrategy = FlowStrategy(payable(config.FlowStrategy));

        AuctionProposalData memory proposalData =
            _getAuctionProposalData(environment, flowStrategyGovernor, flowStrategy);
        require(proposalData.startPrice <= (type(uint128).max / proposalData.amount), "Start price overflow");
        _printProposalData(proposalData);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        (address atmAuction, uint256 proposalId) = _propose(flowStrategyGovernor, flowStrategy, proposalData);

        vm.stopBroadcast();

        console2.log("Auction:                  ", atmAuction);
        console2.log("Payment token:            ", AtmAuction(atmAuction).paymentToken());
        console2.log("Proposal ID:              ", proposalId);
        console2.log("Proposal State:           ", _getProposalState(uint256(flowStrategyGovernor.state(proposalId))));
        console2.log("Proposal Needs Queuing:   ", flowStrategyGovernor.proposalNeedsQueuing(proposalId));
    }

    function _propose(
        FlowStrategyGovernor flowStrategyGovernor,
        FlowStrategy flowStrategy,
        AuctionProposalData memory proposalData
    ) internal virtual returns (address atmAuction, uint256 proposalId);

    function _createAuction(
        FlowStrategyGovernor flowStrategyGovernor,
        FlowStrategy flowStrategy,
        AuctionProposalData memory proposalData
    ) internal virtual returns (address atmAuction);

    function _getValuesAndTargets(uint256 _values, address _auction, address _flowStrategy)
        internal
        pure
        returns (uint256[] memory values, address[] memory targets)
    {
        values = new uint256[](2);
        values[0] = _values;
        values[1] = _values;
        targets = new address[](2);
        targets[0] = _flowStrategy;
        targets[1] = _auction;
    }

    function _getProposalState(uint256 _proposalState) internal view returns (string memory state) {
        return getProposalState[_proposalState];
    }
}
