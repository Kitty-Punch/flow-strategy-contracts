pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {USDCToken} from "../test/utils/USDCToken.sol";

contract BondAuctionFillScript is ScriptBase {
    function run() public {
        BondAuction bondAuction = BondAuction(payable(0xB6a79bc0ec9d2911951bF5998198ddCf4fF50C42));
        USDCToken paymentToken = USDCToken(bondAuction.paymentToken());
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
            bondAuction.auction();
        console2.log("Start time:           ", startTime);
        console2.log("Block timestamp:      ", block.timestamp);
        console2.log("Duration:             ", duration);
        console2.log("Start price:          ", startPrice);
        console2.log("End price:            ", endPrice);
        console2.log("Amount:               ", _amount);
        // 10000

        uint128 price = bondAuction.getCurrentPrice(block.timestamp);
        uint128 totalCost = amount * price;
        console2.log("Price:                ", price);
        console2.log("Total cost:           ", totalCost);

        vm.startBroadcast(privateKey);

        if (mintTokens) {
            paymentToken.mint(executor, totalCost);
        }

        paymentToken.approve(address(bondAuction), type(uint128).max);
        bondAuction.fill(amount);

        vm.stopBroadcast();

        console2.log("Amount:               ", amount);
    }
}
