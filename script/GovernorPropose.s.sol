pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";

contract GovernorProposeScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        FlowStrategyGovernor flowStrategyGovernor = FlowStrategyGovernor(payable(config.FlowStrategyGovernor));
        flowStrategyGovernor.votingDelay();
        AtmAuction atmAuction = AtmAuction(payable(config.AtmAuction));
        uint64 _startTime = uint64(
            block.timestamp + flowStrategyGovernor.votingDelay() + flowStrategyGovernor.votingPeriod() + 2 minutes
        );
        uint64 _duration = 1 hours;
        uint128 _startPrice = 10_000e6;
        uint128 _endPrice = 3_000e6;
        uint128 _amount = 5000e18;

        require(_startPrice <= (type(uint128).max / _amount), "Start price overflow");

        address[] memory targets = new address[](1);
        targets[0] = address(atmAuction);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector, _startTime, _duration, _startPrice, _endPrice, _amount
        );

        string memory description = "Initial ATM auction.";

        uint256 proposalId =
            flowStrategyGovernor.hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);

        console2.log("Duration:         ", _duration);
        console2.log("Start time:       ", _startTime);
        console2.log("Start price:      ", _startPrice);
        console2.log("End price:        ", _endPrice);
        console2.log("Amount:           ", _amount);
        console2.log("Executor:         ", executor);
        console2.log("Executor balance: ", executor.balance);
        console2.log("Proposal ID:      ", proposalId);

        vm.startBroadcast(privateKey);

        flowStrategyGovernor.propose(targets, values, calldatas, description);

        vm.stopBroadcast();

        /*
            enum ProposalState {
                Pending,
                Active,
                Canceled,
                Defeated,
                Succeeded,
                Queued,
                Expired,
                Executed
            }
        */
        console2.log("Proposal State:           ", uint256(flowStrategyGovernor.state(proposalId)));
        console2.log("Proposal Needs Queuing:   ", flowStrategyGovernor.proposalNeedsQueuing(proposalId));
    }
}
