// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ERC20Votes} from "solady/src/tokens/ERC20Votes.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IFlowStrategy} from "./interfaces/IFlowStrategy.sol";

contract FlowStrategy is ERC20Votes, OwnableRoles, IFlowStrategy {
    uint8 public constant MINTER_ROLE = 1;
    uint8 public constant PAUSER_ROLE = 2;
    bool public isTransferPaused = true;
    error TransferPaused();
    constructor(address _governor) {
        _initializeOwner(_governor);
    }
    function name() public view virtual override(ERC20, IFlowStrategy) returns (string memory) {
        return "FlowStrategy";
    }

    function symbol() public view virtual override(ERC20, IFlowStrategy) returns (string memory) {
        return "FLOWSTR";
    }

    function mint(address _to, uint256 _amount) public onlyOwnerOrRoles(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function getPastTotalSupply(uint256 timepoint) public view virtual returns (uint256) {
        return getPastVotesTotalSupply(timepoint);
    }

    function _beforeTokenTransfer(address from, address, uint256) internal virtual override {
        if(from != address(0) && isTransferPaused) {
            revert TransferPaused();
        }
    }

    function setIsTransferPaused(bool _isTransferPaused) public onlyOwnerOrRoles(PAUSER_ROLE) {
        isTransferPaused = _isTransferPaused;
    }
}