pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {AtmAuction} from "../src/AtmAuction.sol";
import {USDCToken} from "../test/utils/USDCToken.sol";

contract AtmAuctionFillScript is ScriptBase {
    function run() public {
        AtmAuction atmAuction = AtmAuction(payable(0xf44F4FA0F59DAD88e4B6b864a8D72C67a3cB821D));
        USDCToken paymentToken = USDCToken(atmAuction.paymentToken());
        uint128 amount = 100e18;
        bool mintTokens = true;

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);

        console2.log("Executor:             ", executor);
        console2.log("Executor balance:     ", executor.balance);
        console2.log("Amount:               ", amount);
        console2.log("Payment token:        ", address(paymentToken));
        console2.log("Payment token balance: ", paymentToken.balanceOf(executor));
        (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 _amount) =
            atmAuction.auction();
        console2.log("Start time:           ", startTime);
        console2.log("Block timestamp:      ", block.timestamp);
        console2.log("Duration:             ", duration);
        console2.log("Start price:          ", startPrice);
        console2.log("End price:            ", endPrice);
        console2.log("Amount:               ", _amount);
        // 10000

        uint128 price = atmAuction.getCurrentPrice(block.timestamp);
        uint128 totalCost = amount * price;
        console2.log("Price:                ", price);
        console2.log("Total cost:           ", totalCost);

        vm.startBroadcast(privateKey);

        if (mintTokens) {
            paymentToken.mint(executor, totalCost);
        }

        paymentToken.approve(address(atmAuction), type(uint128).max);
        atmAuction.fill(amount);

        vm.stopBroadcast();

        console2.log("Amount:               ", amount);
    }
}
