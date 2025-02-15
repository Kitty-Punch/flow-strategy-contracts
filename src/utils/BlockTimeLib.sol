pragma solidity 0.8.25;


/**
 * @title BlockTimeLib
 * @dev Library for converting between seconds and blocks
 * @notice This is used in the Flow network, and the block time is 0.8 seconds per block.
 */
library BlockTimeLib {
    uint256 constant FLOW_TIME_BLOCK = 80000;
    uint256 constant FLOW_TIME_BLOCK_PRECISION = 100000;

    function _toBlocks(uint256 _timeInSeconds) internal pure returns (uint256) {
        return _timeInSeconds * FLOW_TIME_BLOCK_PRECISION / FLOW_TIME_BLOCK;
    }

    function _toSeconds(uint256 _blocks) internal pure returns (uint256) {
        return _blocks * FLOW_TIME_BLOCK / FLOW_TIME_BLOCK_PRECISION;
    }
}
