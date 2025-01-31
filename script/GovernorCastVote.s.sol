pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";

contract GovernorCastVoteScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        FlowStrategyGovernor flowStrategyGovernor = FlowStrategyGovernor(payable(config.FlowStrategyGovernor));
        uint256 proposalId = 87329991636665055878886487169115020485395279143719973045932130188571417227985;
        uint8 vote = 1;

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);
        console2.log("Executor:             ", executor);
        console2.log("Executor balance:     ", executor.balance);
        console2.log("Proposal ID:          ", proposalId);
        console2.log("Proposal State:       ", uint256(flowStrategyGovernor.state(proposalId)));
        console2.log("Proposal Has Voted:   ", flowStrategyGovernor.hasVoted(proposalId, executor));

        vm.startBroadcast(privateKey);

        flowStrategyGovernor.castVote(proposalId, vote);

        vm.stopBroadcast();

        console2.log("Proposal ID: ", proposalId);
        console2.log("Proposal State: ", uint256(flowStrategyGovernor.state(proposalId)));
        console2.log("Proposal Has Voted: ", flowStrategyGovernor.hasVoted(proposalId, executor));
    }
}
