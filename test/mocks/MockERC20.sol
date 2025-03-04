// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMintable} from "../../src/interfaces/IMintable.sol";

contract MockERC20 is ERC20, IMintable {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address account, uint256 amount) external override {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
} 