pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./utils/BaseTest.t.sol";
import {FlowStrategy} from "../src/FlowStrategy.sol";
import {Ownable} from "solady/src/auth/OwnableRoles.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";

contract FlowStrategyTest is BaseTest {
function test_constructor_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    assertEq(flowStrategy.owner(), address(governor), "governor not assigned correctly");
  }

  function test_mint_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.startPrank(address(governor));
    flowStrategy.mint(address(alice), 100e18);
    assertEq(flowStrategy.balanceOf(address(alice)), 100e18, "balance not assigned correctly");
  }

  function test_mint_revert_unauthorized() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.expectRevert(Ownable.Unauthorized.selector);
    flowStrategy.mint(address(alice), 100e18);
  }

  function test_mint_success_with_role() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    address admin = address(1);
    uint8 role = flowStrategy.MINTER_ROLE();
    vm.prank(address(governor));
    flowStrategy.grantRoles(admin, role);
    vm.prank(admin);
    flowStrategy.mint(address(alice), 100e18);
    assertEq(flowStrategy.balanceOf(address(alice)), 100e18, "balance not assigned correctly");
  }

  function test_name_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    assertEq(flowStrategy.name(), "FlowStrategy", "name not assigned correctly");
  }

  function test_symbol_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    assertEq(flowStrategy.symbol(), "FLOWSR", "symbol not assigned correctly");
  }

  function test_setIsTransferPaused_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.prank(address(governor));
    flowStrategy.setIsTransferPaused(true);
    assertEq(flowStrategy.isTransferPaused(), true, "isTransferPaused not assigned correctly");
  }

  function test_setIsTransferPaused_revert_unauthorized() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.expectRevert(Ownable.Unauthorized.selector);
    flowStrategy.setIsTransferPaused(true);
  }

  function test_transfer_revert_transferPaused() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.prank(address(governor));
    flowStrategy.mint(address(alice), 1);
    vm.prank(address(alice));
    vm.expectRevert(FlowStrategy.TransferPaused.selector);
    flowStrategy.transfer(bob, 1);
  }

  function test_transfer_success() public {
    FlowStrategy flowStrategy = new FlowStrategy(address(governor));
    vm.prank(address(governor));
    flowStrategy.mint(address(alice), 1);
    vm.startPrank(address(governor));
    flowStrategy.grantRoles(charlie, flowStrategy.PAUSER_ROLE());
    vm.stopPrank();
    vm.prank(charlie);
    flowStrategy.setIsTransferPaused(false);
    vm.prank(address(alice));
    vm.expectEmit();
    emit ERC20.Transfer(address(alice), address(bob), 1);
    flowStrategy.transfer(bob, 1);
  }
}