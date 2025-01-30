// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CommonBase} from "forge-std/Base.sol";
import {Deposit} from "../../../src/Deposit.sol";
import {IFlowStrategy} from "../../../src/interfaces/IFlowStrategy.sol";

contract DepositHandler is CommonBase {
    Deposit internal _deposit;
    address internal _operator;
    
    constructor(Deposit deposit) {
        _deposit = deposit;
        _operator = _deposit.operator();
    }

    function deposit(address _depositor, uint256 _amount) external returns (uint256 shares, uint256 assets) {
        // Ensure amount doesn't exceed deposit cap
        uint256 remainingCap = _deposit.getDepositCap();
        if (_amount > remainingCap) {
            _amount = remainingCap;
        }

        // Fund the depositor
        vm.deal(_depositor, _amount);
        
        // Make deposit
        vm.startPrank(_depositor);
        shares = _deposit.deposit{value: _amount}();
        vm.stopPrank();
        assets = _amount;
    }

    function addWhitelist(address[] calldata _accounts) external {
        vm.startPrank(_operator);
        _deposit.addWhitelist(_accounts);
        vm.stopPrank();
    }

    function removeWhitelist(address[] calldata _accounts) external {
        vm.startPrank(_operator);
        _deposit.removeWhitelist(_accounts);
        vm.stopPrank();
    }

    function setWhiteListEnabled(bool _enabled) external {
        vm.startPrank(_operator);
        _deposit.setWhiteListEnabled(_enabled);
        vm.stopPrank();
    }
} 