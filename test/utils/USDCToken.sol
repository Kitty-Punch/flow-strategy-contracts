// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ERC20} from "solady/src/tokens/ERC20.sol";

contract USDCToken is ERC20 {
    function name() public view virtual override returns (string memory) {
        return "USDC";
    }

    function symbol() public view virtual override returns (string memory) {
        return "Circle USD";
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}