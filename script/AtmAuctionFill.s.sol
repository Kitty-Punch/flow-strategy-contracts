pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {USDCToken} from "../test/utils/USDCToken.sol";

contract AtmAuctionFillScript is ScriptBase {
    function run() public {
        string memory environment = "testnet"; // testnet or mainnet
        DeployedConfig memory config = _parseDeployedConfig(environment);
        AtmAuction atmAuction = AtmAuction(payable(config.AtmAuction));
        USDCToken paymentToken = USDCToken(atmAuction.paymentToken());
        uint128 amount = 1000e18;
        uint128 price = atmAuction.getCurrentPrice(block.timestamp);
        uint128 totalCost = amount * price;
        bool mintTokens = true;

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);
        console2.log("Executor:             ", executor);
        console2.log("Executor balance:     ", executor.balance);
        console2.log("Amount:               ", amount);
        console2.log("Payment token:        ", address(paymentToken));
        console2.log("Payment token balance: ", paymentToken.balanceOf(executor));

        vm.startBroadcast(privateKey);

        if (mintTokens) {
            paymentToken.mint(executor, totalCost);
        }

        paymentToken.approve(address(atmAuction), totalCost);
        atmAuction.fill(amount);

        vm.stopBroadcast();

        console2.log("Amount:               ", amount);
    }
}
