pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategyGovernor} from "../src/FlowStrategyGovernor.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";


contract GovernorExecuteScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        FlowStrategyGovernor flowStrategyGovernor = FlowStrategyGovernor(payable(config.FlowStrategyGovernor));
        FlowStrategy flowStrategy = FlowStrategy(payable(config.FlowStrategy));
        AtmAuction auction = AtmAuction(payable(0xDA7AD88EFACD79049aFf47C99f1f775f15F0b1dA));
        uint64 _startTime = 1738559950;
        uint64 _duration = 15 hours;
        uint128 _startPrice = 10e6;
        uint128 _endPrice = 5e6;
        uint128 _amount = 5000e18;

        require(_startPrice <= (type(uint128).max / _amount), "Start price overflow");

        address[] memory targets = new address[](2);
        targets[0] = address(flowStrategy);
        targets[1] = address(auction);
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory callDatas = new bytes[](2);
        callDatas[0] = abi.encodeWithSelector(
            OwnableRoles.grantRoles.selector,
            auction,
            flowStrategy.MINTER_ROLE()
        );
        callDatas[1] = abi.encodeWithSelector(
            DutchAuction.startAuction.selector,
            _startTime,
            _duration,
            _startPrice,
            _endPrice,
            _amount
        );
        
        string memory description = "Initial ATM auction.";
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        uint256 proposalId =
            flowStrategyGovernor.hashProposal(targets, values, callDatas, descriptionHash);

        console2.log("Block timestamp:      ", block.timestamp);
        console2.log("Start time:           ", _startTime);
        console2.log("Proposal ID:          ", proposalId);
        console2.log("Proposal State:       ", uint256(flowStrategyGovernor.state(proposalId)));
        console2.log("Proposal Deadline:    ", flowStrategyGovernor.proposalDeadline(proposalId));

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        flowStrategyGovernor.execute(targets, values, callDatas, descriptionHash);

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
