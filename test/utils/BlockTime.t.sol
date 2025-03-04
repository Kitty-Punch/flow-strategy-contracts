pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {BlockTimeLib} from "../../src/utils/BlockTimeLib.sol";

contract BlockTimeTest is Test {

    uint32 constant BLOCKS_PER_DAY = 108000;

    function test_blocksPerDays_success(uint16 _days) external pure {
        vm.assume(_days > 0);
        vm.assume(_days < 365 * 100); // 100 years
        uint256 _expectedBlocks = BLOCKS_PER_DAY * _days;
        uint256 daysInSeconds = _days * uint256(1 days);
        
        uint256 inBlock = BlockTimeLib._toBlocks(daysInSeconds);

        assertEq(inBlock, _expectedBlocks, "Blocks mismatch");
    }

    function test_toBlocks_toSeconds_success(uint232 _inTime) external pure {
        uint256 inBlock = BlockTimeLib._toBlocks(_inTime);
        uint256 outTime = BlockTimeLib._toSeconds(inBlock);

        assertApproxEqAbs(_inTime, outTime, 1, "Time mismatch");
    }
}
