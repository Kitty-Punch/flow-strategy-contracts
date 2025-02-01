pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";

contract FlowStrategyDelegateScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        FlowStrategy flowStrategy = FlowStrategy(payable(config.FlowStrategy));
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);
        address delegatee = executor;
        console2.log("Executor:         ", executor);
        console2.log("Delegatee:        ", delegatee);

        vm.startBroadcast(privateKey);

        flowStrategy.delegate(delegatee);

        vm.stopBroadcast();
    }
}
