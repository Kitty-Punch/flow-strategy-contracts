// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {DutchAuction} from "./DutchAuction.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IFlowStrategy} from "./interfaces/IFlowStrategy.sol";
import {TokenPriceLib} from "./utils/TokenPriceLib.sol";

contract BondAuction is DutchAuction {
    struct Bond {
        uint128 amount;
        uint128 price;
        uint64 startRedemption;
    }

    error UnredeemedBond();
    error NoBondToRedeem();
    error RedemptionWindowNotStarted();
    error RedemptionWindowPassed();
    error NoBondToWithdraw();

    mapping(address => Bond) public bonds;
    uint256 public constant REDEMPTION_WINDOW = 1 days;

    constructor(address _flowStrategy, address _governor, address _paymentToken)
        DutchAuction(_flowStrategy, _governor, _paymentToken)
    {}

    function _fill(uint128 amount, uint128 price, uint64 startTime, uint64 duration) internal override {
        super._fill(amount, price, startTime, duration);
        if (bonds[msg.sender].startRedemption != 0) {
            revert UnredeemedBond();
        }
        uint256 paymentAmount = TokenPriceLib._normalize(price, amount, PRICE_DECIMALS, paymentToken, flowStrategy);
        SafeTransferLib.safeTransferFrom(paymentToken, msg.sender, address(this), paymentAmount);
        bonds[msg.sender] = Bond({amount: amount, price: price, startRedemption: startTime + duration});
    }

    function redeem() external {
        _redeem();
    }

    function _redeem() internal {
        Bond memory bond = bonds[msg.sender];
        // slither-disable-next-line incorrect-equality
        if (bond.startRedemption == 0) {
            revert NoBondToRedeem();
        }
        uint256 currentTime = block.timestamp;
        if (currentTime < bond.startRedemption) {
            revert RedemptionWindowNotStarted();
        }
        if (currentTime > bond.startRedemption + REDEMPTION_WINDOW) {
            revert RedemptionWindowPassed();
        }
        delete bonds[msg.sender];
        uint256 paymentAmount =
            TokenPriceLib._normalize(bond.price, bond.amount, PRICE_DECIMALS, paymentToken, flowStrategy);
        SafeTransferLib.safeTransfer(paymentToken, owner(), paymentAmount);
        IFlowStrategy(flowStrategy).mint(msg.sender, bond.amount);
    }

    function withdraw() external {
        _withdraw();
    }

    function _withdraw() internal {
        Bond memory bond = bonds[msg.sender];
        // slither-disable-next-line incorrect-equality
        if (bond.startRedemption == 0) {
            revert NoBondToWithdraw();
        }
        uint256 currentTime = block.timestamp;
        if (currentTime < bond.startRedemption) {
            revert RedemptionWindowNotStarted();
        }
        uint256 paymentAmount =
            TokenPriceLib._normalize(bond.price, bond.amount, PRICE_DECIMALS, paymentToken, flowStrategy);
        SafeTransferLib.safeTransfer(paymentToken, msg.sender, paymentAmount);
        delete bonds[msg.sender];
    }
}
