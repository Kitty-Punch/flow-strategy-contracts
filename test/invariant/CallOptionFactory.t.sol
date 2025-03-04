// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CallOptionFactory} from "../../src/options/CallOptionFactory.sol";
import {CallOption} from "../../src/options/CallOption.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {CallOptionFactoryHandler} from "./handlers/CallOptionFactoryHandler.sol";
import {CallOptionFactoryActorManager} from "./managers/CallOptionFactoryActorManager.sol";
import {LinearDecayPremiumCalculator} from "../../src/options/premiums/LinearDecayPremiumCalculator.sol";
import {IPremiumCalculator} from "../../src/interfaces/options/IPremiumCalculator.sol";

contract CallOptionFactoryInvariantTest is Test {
    uint256 internal constant TOTAL_HANDLERS = 10;
    uint256 internal constant TOTAL_PAYMENT_TOKENS = 5;
    uint256 internal constant BASE_PREMIUM_RATE_BPS = 500;

    address internal underlyingToken;
    address internal treasury;
    address internal governor;
    address[] internal paymentTokens;
    IPremiumCalculator internal premiumCalculator;
    CallOptionFactory internal factory;
    CallOptionFactoryHandler[] internal handlers;
    CallOptionFactoryActorManager public actorManager;

    // Test tokens
    MockERC20 public underlying;
    MockERC20 public strikeAsset;

    function setUp() public {
        treasury = vm.createWallet("treasury").addr;
        governor = vm.createWallet("governor").addr;
        underlyingToken = address(new MockERC20("Underlying", "UNDER", 18));
        vm.label(underlyingToken, "underlyingToken");

        premiumCalculator = new LinearDecayPremiumCalculator(BASE_PREMIUM_RATE_BPS);
        vm.label(address(premiumCalculator), "premiumCalculator");

        factory = new CallOptionFactory(address(underlyingToken), treasury, governor);
        vm.label(address(factory), "factory");

        handlers = new CallOptionFactoryHandler[](TOTAL_HANDLERS);

        for (uint256 i = 0; i < TOTAL_HANDLERS; i++) {
            handlers[i] = new CallOptionFactoryHandler(factory);
            vm.label(address(handlers[i]), string.concat("Handler_", vm.toString(i)));
        }

        paymentTokens = new address[](TOTAL_PAYMENT_TOKENS);
        uint8 paymentTokenDecimals = 18;
        for (uint256 i = 0; i < TOTAL_PAYMENT_TOKENS; i++) {
            paymentTokens[i] = address(
                new MockERC20(
                    string.concat("PaymentToken_", vm.toString(i)),
                    string.concat("PT_", vm.toString(i)),
                    paymentTokenDecimals
                )
            );
            vm.label(
                paymentTokens[i], string.concat("PaymentToken_", vm.toString(paymentTokenDecimals), "_", vm.toString(i))
            );
            paymentTokenDecimals = paymentTokenDecimals == 18 ? 6 : 18;
        }

        // Create actor manager
        actorManager = new CallOptionFactoryActorManager(handlers, premiumCalculator, paymentTokens);
        vm.label(address(actorManager), "actorManager");

        // Target contract functions for invariant testing
        targetContract(address(actorManager));
    }

    function invariant_treasury_balance_eq_total_paid() external view {
        (address[] memory _paymentTokens, uint256[] memory _totalPaid) = actorManager.totalPaid();
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            assertEq(
                _totalPaid[i],
                IERC20(_paymentTokens[i]).balanceOf(address(factory.treasury())),
                "Total paid mismatch"
            );
        }
    }

    function invariant_total_underlying_tokens_sold_eq_total_supply() external view {
        assertEq(
            actorManager.totalUnderlyingTokensSold(),
            IERC20(underlyingToken).totalSupply(),
            "Total underlying tokens sold mismatch"
        );
    }
    /*
    function invariant_totalOptionsMatchTracked() public {
        uint256 actualTotal = factory.totalOptions();
        uint256 trackedTotal = 0;

        // Sum up options created across all handlers
        for (uint256 i = 0; i < NUM_ACTORS; i++) {
            CallOptionFactoryHandler handler = actorManager.getHandler(i);
            trackedTotal += handler.totalOptionsCreated();
        }

        assertEq(actualTotal, trackedTotal, "Total options mismatch");
    }

    // Add more invariants here
    function invariant_optionsAreValid() public {
        for (uint256 i = 0; i < NUM_ACTORS; i++) {
            CallOptionFactoryHandler handler = actorManager.getHandler(i);
            for (uint256 j = 0; j < handler.totalOptionsCreated(); j++) {
                address optionAddress = handler.getOptionAddress(j);
                assertTrue(optionAddress != address(0), "Option address should not be zero");
                assertTrue(factory.isCallOption(optionAddress), "Address should be registered as call option");
            }
        }
    }
    */
}
