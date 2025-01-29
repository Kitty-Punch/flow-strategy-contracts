// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IGovernor, Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract FlowStrategyGovernor is 
    Governor, 
    GovernorVotes, 
    GovernorCountingSimple, 
    GovernorVotesQuorumFraction 
{
    uint256 immutable votingDelay_;
    uint256 immutable votingPeriod_;
    uint256 immutable proposalThreshold_;
    constructor(
        IVotes _token,
        uint256 _quorumPercentage,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    )
        Governor("EthStrategyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
    {
        votingDelay_ = _votingDelay;
        votingPeriod_ = _votingPeriod;
        proposalThreshold_ = _proposalThreshold;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override returns (uint256) {
        return votingDelay_; // 1 day at 12 sec block time
    }

    function votingPeriod() public view override returns (uint256) {
        return votingPeriod_; // 1 week at 12 sec block time
    }

    function proposalThreshold() public view override returns (uint256) {
        return proposalThreshold_; // Minimum token threshold to propose (e.g., 1000 tokens)
    }
}