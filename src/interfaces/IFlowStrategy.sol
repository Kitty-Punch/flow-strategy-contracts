// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IFlowStrategy {
    function mint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);
}
