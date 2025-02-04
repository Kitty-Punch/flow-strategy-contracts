// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DutchAuction is OwnableRoles, ReentrancyGuard {
    error InvalidStartTime();
    error AuctionAlreadyActive();
    error AuctionNotActive();
    error InvalidStartPrice();
    error AmountExceedsSupply();
    error InvalidDuration();
    error AmountStartPriceOverflow();
    error FillAmountZero();

    struct Auction {
        uint64 startTime;
        uint64 duration;
        uint128 startPrice;
        uint128 endPrice;
        uint128 amount;
    }

    Auction public auction;

    address public immutable ethStrategy;
    address public immutable paymentToken;

    uint8 public constant PRICE_DECIMALS = 6;
    uint64 public constant MAX_START_TIME_WINDOW = 7 days;
    uint64 public constant MAX_DURATION = 30 days;

    event AuctionStarted(Auction auction);
    event AuctionFilled(address buyer, uint128 amount, uint128 price);
    event AuctionEndedEarly();
    event AuctionCancelled();

    uint8 public constant ADMIN_ROLE = 1;

    constructor(address _ethStrategy, address _governor, address _paymentToken) {
        require(_ethStrategy != address(0), "Strategy is invalid");
        require(_governor != address(0), "Governor is invalid");
        require(_paymentToken != address(0), "Payment token is invalid");
        ethStrategy = _ethStrategy;
        paymentToken = _paymentToken;
        _initializeOwner(_governor);
    }

    function startAuction(uint64 _startTime, uint64 _duration, uint128 _startPrice, uint128 _endPrice, uint128 _amount)
        public
        onlyOwnerOrRoles(ADMIN_ROLE)
    {
        uint64 currentTime = uint64(block.timestamp);
        if (_startTime == 0) {
            _startTime = currentTime;
        }
        if (_startTime < currentTime || _startTime > currentTime + MAX_START_TIME_WINDOW) {
            revert InvalidStartTime();
        }
        if (_duration == 0 || _duration > MAX_DURATION) {
            revert InvalidDuration();
        }
        if (_startPrice > (type(uint128).max / _amount)) {
            revert AmountStartPriceOverflow();
        }
        Auction memory _auction = auction;
        if (_isAuctionActive(_auction, currentTime)) {
            revert AuctionAlreadyActive();
        }
        delete auction;
        if (_startPrice < _endPrice || _endPrice == 0) {
            revert InvalidStartPrice();
        }
        _auction = Auction({
            startTime: _startTime,
            duration: _duration,
            startPrice: _startPrice,
            endPrice: _endPrice,
            amount: _amount
        });
        auction = _auction;

        emit AuctionStarted(_auction);
    }

    function cancelAuction() public onlyOwnerOrRoles(ADMIN_ROLE) {
        delete auction;
        emit AuctionCancelled();
    }

    function fill(uint128 _amount) public nonReentrant {
        Auction memory _auction = auction;
        uint256 currentTime = block.timestamp;
        if (!_isAuctionActive(_auction, currentTime)) {
            revert AuctionNotActive();
        }
        if (_amount == 0) {
            revert FillAmountZero();
        }
        if (_amount > _auction.amount) {
            revert AmountExceedsSupply();
        }
        uint128 currentPrice = _getCurrentPrice(_auction, currentTime);
        uint128 delta_amount = _auction.amount - _amount;
        if (delta_amount > 0) {
            auction.amount = delta_amount;
        } else {
            delete auction;
            emit AuctionEndedEarly();
        }
        _fill(_amount, currentPrice, _auction.startTime, _auction.duration);
    }

    function _fill(uint128 amount, uint128 price, uint64, uint64) internal virtual {
        emit AuctionFilled(msg.sender, amount, price);
    }

    function _isAuctionActive(Auction memory _auction, uint256 currentTime) internal pure returns (bool) {
        return _auction.startTime > 0 && _auction.startTime + _auction.duration > currentTime
            && currentTime >= _auction.startTime;
    }

    function _getCurrentPrice(Auction memory _auction, uint256 currentTime) internal pure returns (uint128) {
        uint256 delta_p = _auction.startPrice - _auction.endPrice;
        uint256 delta_t = _auction.duration - (currentTime - _auction.startTime);
        return uint128(((delta_p * delta_t) / _auction.duration) + _auction.endPrice);
    }

    function getCurrentPrice(uint256 currentTime) external view returns (uint128) {
        Auction memory _auction = auction;
        if (!_isAuctionActive(_auction, currentTime)) {
            revert AuctionNotActive();
        }
        return _getCurrentPrice(_auction, currentTime);
    }

    function isAuctionActive(uint256 currentTime) external view returns (bool) {
        Auction memory _auction = auction;
        return _isAuctionActive(_auction, currentTime);
    }
}
