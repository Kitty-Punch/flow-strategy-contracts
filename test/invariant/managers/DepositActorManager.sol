// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Deposit} from "../../../src/Deposit.sol";
import {DepositHandler} from "../handlers/DepositHandler.sol";

contract DepositActorManager is CommonBase, StdCheats, StdUtils {
    Deposit internal _deposit;
    DepositHandler[] internal _handlers;

    uint256 public totalDeposited;
    uint256 public totalShares;

    constructor(Deposit deposit, DepositHandler[] memory handlers) {
        _deposit = deposit;

        for (uint256 i = 0; i < handlers.length; i++) {
            _handlers.push(handlers[i]);
        }
    }

    function deposit(uint256 handlerIndex, address user, uint256 amount) external {
        // Bound the deposit amount between MIN_DEPOSIT and MAX_DEPOSIT
        amount = bound(amount, _deposit.MIN_DEPOSIT(), _deposit.MAX_DEPOSIT());
        DepositHandler handler = _handlers[bound(handlerIndex, 0, _handlers.length - 1)];
        (uint256 shares, uint256 assets) = handler.deposit(user, amount);
        totalDeposited += assets;
        totalShares += shares;
    }

    function addWhitelist(uint256 handlerIndex, address[] calldata accounts) external {
        DepositHandler handler = _handlers[bound(handlerIndex, 0, _handlers.length - 1)];
        handler.addWhitelist(accounts);
    }

    function removeWhitelist(uint256 handlerIndex, address[] calldata accounts) external {
        DepositHandler handler = _handlers[bound(handlerIndex, 0, _handlers.length - 1)];
        handler.removeWhitelist(accounts);
    }

    function setWhiteListEnabled(uint256 handlerIndex, bool enabled) external {
        DepositHandler handler = _handlers[bound(handlerIndex, 0, _handlers.length - 1)];
        handler.setWhiteListEnabled(enabled);
    }
}
