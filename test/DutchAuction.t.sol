pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./utils/BaseTest.t.sol";
import {DutchAuction} from "../src/DutchAuction.sol";
import {Ownable} from "solady/src/auth/OwnableRoles.sol";
contract DutchAuctionTest is BaseTest {
  DutchAuction dutchAuction;

  uint64 defaultDuration = 1 days;
  uint128 defaultStartPrice = 10_000e6;
  uint128 defaultEndPrice = 3_000e6;
  uint128 defaultAmount = 100e18;

  function setUp() public override virtual {
    super.setUp();
    dutchAuction = new DutchAuction(
      address(ethStrategy),
      address(governor),
      address(usdcToken)
    );
    vm.startPrank(address(governor));
    ethStrategy.grantRoles(address(dutchAuction), ethStrategy.MINTER_ROLE());
    dutchAuction.grantRoles(admin1.addr, dutchAuction.ADMIN_ROLE());
    dutchAuction.grantRoles(admin2.addr, dutchAuction.ADMIN_ROLE());
    vm.stopPrank();
  }

  function test_startAuction_success_1() public {
    vm.startPrank(admin1.addr);
    DutchAuction.Auction memory auction = DutchAuction.Auction({
      startTime: uint64(block.timestamp),
      duration: defaultDuration,
      startPrice: defaultStartPrice,
      endPrice: defaultEndPrice,
      amount: defaultAmount
    });
    vm.expectEmit();
    emit DutchAuction.AuctionStarted(auction);
    dutchAuction.startAuction(uint64(block.timestamp), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(block.timestamp), "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, defaultAmount, "amount not assigned correctly");
  }

  function test_startAuction_success_2() public {
    vm.startPrank(admin1.addr);
    DutchAuction.Auction memory auction = DutchAuction.Auction({
      startTime: uint64(block.timestamp),
      duration: defaultDuration,
      startPrice: defaultStartPrice,
      endPrice: defaultEndPrice,
      amount: defaultAmount
    });
    vm.expectEmit();
    emit DutchAuction.AuctionStarted(auction);
    dutchAuction.startAuction(uint64(0), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(block.timestamp), "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, defaultAmount, "amount not assigned correctly");
  }

  function test_startAuction_invalidStartTime_1() public {
    vm.warp(block.timestamp + 1);
    uint256 currentTime = block.timestamp;
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.InvalidStartTime.selector);
    dutchAuction.startAuction(uint64(currentTime - 1), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_invalidDuration_1() public {
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.InvalidDuration.selector);
    dutchAuction.startAuction(uint64(block.timestamp), 0, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_invalidDuration_2() public {
    uint64 maxDuration = dutchAuction.MAX_DURATION();
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.InvalidDuration.selector);
    dutchAuction.startAuction(uint64(block.timestamp), maxDuration + 1, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }
  function test_startAuction_invalidStartTime_2() public {
      uint256 currentTime = block.timestamp;
      vm.startPrank(admin1.addr);
      uint256 maxStartTimeWindow = dutchAuction.MAX_START_TIME_WINDOW();
      vm.expectRevert(DutchAuction.InvalidStartTime.selector);
      dutchAuction.startAuction(uint64(currentTime + maxStartTimeWindow + 1), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
      vm.stopPrank();
      (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
      assertEq(startTime, uint64(0), "startTime not assigned correctly");
      assertEq(duration, 0, "duration not assigned correctly");
      assertEq(startPrice, 0, "startPrice not assigned correctly");
      assertEq(endPrice, 0, "endPrice not assigned correctly");
      assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_invalidStartPrice_1() public {
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.InvalidStartPrice.selector);
    dutchAuction.startAuction(uint64(block.timestamp), defaultDuration, defaultEndPrice, defaultStartPrice, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_invalidStartPrice_2() public {
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.InvalidStartPrice.selector);
    dutchAuction.startAuction(uint64(block.timestamp), defaultDuration, defaultStartPrice, 0, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_amountStartPriceOverflow() public {
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.AmountStartPriceOverflow.selector);
    dutchAuction.startAuction(uint64(block.timestamp), defaultDuration, (type(uint128).max / defaultAmount) + 1, defaultEndPrice, defaultAmount);
    vm.stopPrank();
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_unauthorized() public {
    vm.warp(block.timestamp + 1);
    uint256 currentTime = block.timestamp;
    vm.expectRevert(Ownable.Unauthorized.selector);
    dutchAuction.startAuction(uint64(currentTime - 1), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_startAuction_auctionAlreadyActive() public {
    test_startAuction_success_1();
    vm.startPrank(admin1.addr);
    vm.expectRevert(DutchAuction.AuctionAlreadyActive.selector);
    dutchAuction.startAuction(uint64(block.timestamp), defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();
  }

  // fill the max amount (deletes the auction and emits AuctionEndedEarly)
  function test_fill_success_1() public virtual{
    test_startAuction_success_1();
    vm.prank(alice);
    vm.expectEmit();
    emit DutchAuction.AuctionEndedEarly();
    vm.expectEmit();
    emit DutchAuction.AuctionFilled(alice, defaultAmount, defaultStartPrice);
    dutchAuction.fill(defaultAmount);

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  // fill less than the max amount
  function test_fill_success_2() public virtual {
    test_startAuction_success_1();
    vm.prank(alice);
    vm.expectEmit();
    emit DutchAuction.AuctionFilled(alice, defaultAmount - 1, defaultStartPrice);
    dutchAuction.fill(defaultAmount - 1);

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, block.timestamp, "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, 1, "amount not assigned correctly");
  }

  // starting when there is no auction
  function test_fill_auctionNotActive_1() public {
    vm.prank(alice);
    vm.expectRevert(DutchAuction.AuctionNotActive.selector);
    dutchAuction.fill(defaultAmount);

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  // starting after the auction ended
  function test_fill_auctionNotActive_2() public {
    uint256 expectedStartTime = block.timestamp;
    test_startAuction_success_1();
    vm.warp(block.timestamp + defaultDuration);
    vm.prank(alice);
    vm.expectRevert(DutchAuction.AuctionNotActive.selector);
    dutchAuction.fill(defaultAmount);

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, expectedStartTime, "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, defaultAmount, "amount not assigned correctly");
  }

  // starting before the auction starts
  function test_fill_auctionNotActive_3() public {
    uint64 expectedStartTime = uint64(block.timestamp + 1 days);

    vm.startPrank(admin1.addr);
    DutchAuction.Auction memory auction = DutchAuction.Auction({
      startTime: expectedStartTime,
      duration: defaultDuration,
      startPrice: defaultStartPrice,
      endPrice: defaultEndPrice,
      amount: defaultAmount
    });
    vm.expectEmit();
    emit DutchAuction.AuctionStarted(auction);
    dutchAuction.startAuction(expectedStartTime, defaultDuration, defaultStartPrice, defaultEndPrice, defaultAmount);
    vm.stopPrank();

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, expectedStartTime, "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, defaultAmount, "amount not assigned correctly");

    vm.warp(block.timestamp + 23 hours);
    vm.prank(alice);
    vm.expectRevert(DutchAuction.AuctionNotActive.selector);
    dutchAuction.fill(defaultAmount);

    ( startTime,  duration,  startPrice,  endPrice,  amount) = dutchAuction.auction();
    assertEq(startTime, expectedStartTime, "startTime not assigned correctly");
    assertEq(duration, defaultDuration, "duration not assigned correctly");
    assertEq(startPrice, defaultStartPrice, "startPrice not assigned correctly");
    assertEq(endPrice, defaultEndPrice, "endPrice not assigned correctly");
    assertEq(amount, defaultAmount, "amount not assigned correctly");
  }

  function test_fill_amountExceedsSupply() public {
    test_startAuction_success_1();
    vm.prank(alice);
    vm.expectRevert(DutchAuction.AmountExceedsSupply.selector);
    dutchAuction.fill(defaultAmount + 1);
  }

  function test_fill_fillAmountZero() public {
    test_startAuction_success_1();
    vm.prank(alice);
    vm.expectRevert(DutchAuction.FillAmountZero.selector);
    dutchAuction.fill(0);
  }

  function test_cancelAuction_success() public {
    test_startAuction_success_1();
    vm.startPrank(admin1.addr);
    vm.expectEmit();
    emit DutchAuction.AuctionCancelled();
    dutchAuction.cancelAuction();
    vm.stopPrank();

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, uint64(0), "startTime not assigned correctly");
    assertEq(duration, 0, "duration not assigned correctly");
    assertEq(startPrice, 0, "startPrice not assigned correctly");
    assertEq(endPrice, 0, "endPrice not assigned correctly");
    assertEq(amount, 0, "amount not assigned correctly");
  }

  function test_cancelAuction_unauthorized() public {
    vm.startPrank(alice);
    vm.expectRevert(Ownable.Unauthorized.selector);
    dutchAuction.cancelAuction();
    vm.stopPrank();
  }

  function test_getCurrentPrice_success() public {
    test_startAuction_success_1();
    uint128 currentPrice = dutchAuction.getCurrentPrice(block.timestamp);
    assertEq(currentPrice, defaultStartPrice, "currentPrice not assigned correctly");
  }

  function test_getCurrentPrice_auctionNotActive() public {
    vm.expectRevert(DutchAuction.AuctionNotActive.selector);
    dutchAuction.getCurrentPrice(block.timestamp);
  }

  function test_isAuctionActive_success_1() public {
    test_startAuction_success_1();
    bool isActive = dutchAuction.isAuctionActive(block.timestamp);
    assertTrue(isActive, "auction not active");
  }

  function test_isAuctionActive_success_2() public view {
    bool isActive = dutchAuction.isAuctionActive(block.timestamp);
    assertTrue(!isActive, "auction active");
  }

  function test_isAuctionActive_success_3() public {
    test_startAuction_success_1();
    vm.warp(block.timestamp + defaultDuration);
    bool isActive = dutchAuction.isAuctionActive(block.timestamp);
    assertTrue(!isActive, "auction active");
  }

  function testFuzz_fill(uint128 _amount, uint64 _startTime, uint64 _duration, uint128 _startPrice, uint128 _endPrice, uint64 _elapsedTime, uint128 _totalAmount) public virtual {
    vm.assume(_amount < _totalAmount);
    vm.assume(_amount > 0);
    vm.assume(_startTime > block.timestamp);
    vm.assume(_startTime < block.timestamp + dutchAuction.MAX_START_TIME_WINDOW());
    vm.assume(_duration > 0);
    vm.assume(_duration < dutchAuction.MAX_DURATION());
    vm.assume(_startPrice > 0);
    vm.assume(_endPrice > 0);
    vm.assume(_startPrice >= _endPrice);
    vm.assume(_elapsedTime >= _startTime);
    vm.assume(_elapsedTime < _startTime + _duration);
    vm.assume(_startPrice <= (type(uint128).max / _totalAmount));
    uint64 delta_t = _duration - (_elapsedTime - _startTime);
    uint128 delta_p = _startPrice - _endPrice;
    if(delta_p == 0) {
      delta_p = 1;
    }
    vm.assume(delta_t <= type(uint128).max / delta_p);

    fill(_amount, _startTime, _duration, _startPrice, _endPrice, _elapsedTime, _totalAmount);
  }
  
  function fill(uint128 _amount, uint64 _startTime, uint64 _duration, uint128 _startPrice, uint128 _endPrice, uint64 _elapsedTime, uint128 _totalAmount) public virtual {
    vm.startPrank(admin1.addr);
    DutchAuction.Auction memory auction = DutchAuction.Auction({
      startTime: _startTime,
      duration: _duration,
      startPrice: _startPrice,
      endPrice: _endPrice,
      amount: _totalAmount
    });
    vm.expectEmit();
    emit DutchAuction.AuctionStarted(auction);
    dutchAuction.startAuction(_startTime, _duration, _startPrice, _endPrice, _totalAmount);
    vm.stopPrank();

    (uint64 startTime, uint64 duration, uint128 startPrice, uint128 endPrice, uint128 amount) = dutchAuction.auction();
    assertEq(startTime, _startTime, "startTime not assigned correctly");
    assertEq(duration, _duration, "duration not assigned correctly");
    assertEq(startPrice, _startPrice, "startPrice not assigned correctly");
    assertEq(endPrice, _endPrice, "endPrice not assigned correctly");
    assertEq(amount, _totalAmount, "amount not assigned correctly");

    vm.warp(_elapsedTime);
    uint128 fillPrice = calculateFillPrice(_startTime, _duration, _startPrice, _endPrice, _elapsedTime);
    vm.prank(alice);
    vm.expectEmit();
    emit DutchAuction.AuctionFilled(alice, _amount, fillPrice);
    dutchAuction.fill(_amount);

    ( startTime,  duration,  startPrice,  endPrice,  amount) = dutchAuction.auction();
    assertEq(startTime, _startTime, "startTime not assigned correctly");
    assertEq(duration, _duration, "duration not assigned correctly");
    assertEq(startPrice, _startPrice, "startPrice not assigned correctly");
    assertEq(endPrice, _endPrice, "endPrice not assigned correctly");
    assertEq(amount, _totalAmount - _amount, "amount not assigned correctly");
  }
}