pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {ScriptBase} from "./ScriptBase.s.sol";

contract AuctionStartAuctionScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        AtmAuction atmAuction = AtmAuction(payable(config.AtmAuction));
        uint64 _startTime = uint64(block.timestamp + 2 minutes);
        uint64 _duration = 1 hours;
        uint128 _startPrice = 1e18;
        uint128 _endPrice = 1e15;
        uint128 _amount = 5000e18;

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);
        console2.log("Executor:         ", executor);
        console2.log("Executor balance: ", executor.balance);

        vm.startBroadcast(privateKey);

        atmAuction.startAuction(_startTime, _duration, _startPrice, _endPrice, _amount);

        vm.stopBroadcast();
    }
}
