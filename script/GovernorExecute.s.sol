pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";

contract GovernorExecuteScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        FlowStrategyGovernor flowStrategyGovernor = FlowStrategyGovernor(payable(config.FlowStrategyGovernor));
        AtmAuction atmAuction = AtmAuction(payable(config.AtmAuction));
        uint64 _startTime = 1738386373;
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
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        uint256 proposalId =
            flowStrategyGovernor.hashProposal(targets, values, calldatas, descriptionHash);

        console2.log("Block timestamp:      ", block.timestamp);
        console2.log("Block number:         ", block.number);
        console2.log("Proposal ID:          ", proposalId);
        console2.log("Proposal State:       ", uint256(flowStrategyGovernor.state(proposalId)));
        console2.log("Proposal Deadline:    ", flowStrategyGovernor.proposalDeadline(proposalId));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        flowStrategyGovernor.execute(targets, values, calldatas, descriptionHash);

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
        console2.log("Proposal State:       ", uint256(flowStrategyGovernor.state(proposalId)));
        
    }
}
