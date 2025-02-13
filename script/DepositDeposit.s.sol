pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {Deposit} from "../src/Deposit.sol";
import {ScriptBase} from "./ScriptBase.s.sol";

contract DepositDepositScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);

        uint256 amount = 1000 ether;

        Deposit deposit = Deposit(payable(config.Deposit));
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);
        console2.log("Executor:         ", executor);
        console2.log("Executor balance: ", executor.balance);
        console2.log("DepositCap:       ", deposit.getDepositCap() / 1e18);

        vm.startBroadcast(privateKey);

        uint256 minted = deposit.deposit{value: amount}();

        vm.stopBroadcast();

        console2.log("Shares: ", minted / 1e18);
    }
}
