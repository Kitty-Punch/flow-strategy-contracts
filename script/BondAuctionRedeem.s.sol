pragma solidity 0.8.25;

import {console2} from "forge-std/console2.sol";
import {ScriptBase} from "./ScriptBase.s.sol";
import {BondAuction} from "../src/BondAuction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BondAuctionRedeemScript is ScriptBase {
    function run() public {
        BondAuction bondAuction = BondAuction(payable(0xb06F1FA6Ca0aa0679F1443A7a96529f86f43bafc));
        IERC20 flowStrategy = IERC20(bondAuction.flowStrategy());

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address executor = vm.addr(privateKey);

        console2.log("Executor:             ", executor);

        (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 _amount) =
            bondAuction.auction();
        console2.log("Start time:           ", startTime);
        console2.log("Block timestamp:      ", block.timestamp);
        console2.log("Duration:             ", duration);
        console2.log("Start price:          ", startPrice);
        console2.log("End price:            ", endPrice);
        console2.log("Amount:               ", _amount);

        vm.startBroadcast(privateKey);

        bondAuction.redeem();

        vm.stopBroadcast();

        console2.log("Flow strategy balance: ", flowStrategy.balanceOf(executor));
    }
}
