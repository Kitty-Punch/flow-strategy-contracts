// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IMintable} from "./IMintable.sol";

interface IFlowStrategy is IMintable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);
}
