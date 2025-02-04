pragma solidity 0.8.25;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IFlowStrategy} from "./interfaces/IFlowStrategy.sol";
import {SignatureCheckerLib} from "solady/src/utils/SignatureCheckerLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AllowableAccounts} from "./AllowableAccounts.sol";

contract Deposit is Ownable, ReentrancyGuard, AllowableAccounts {
    uint256 public immutable CONVERSION_RATE;
    uint256 public constant MIN_DEPOSIT = 1_000e18;
    uint256 public constant MAX_DEPOSIT = 5_000_000e18;
    uint256 public constant DENOMINATOR_BP = 100_00;

    error DepositAmountTooLow();
    error DepositAmountTooHigh();
    error DepositFailed();
    error AlreadyRedeemed();
    error DepositCapExceeded();
    error InvalidConversionPremium();
    error InvalidCall();
    error NotWhitelisted();

    event WhiteListEnabledSet(bool whiteListEnabled);
    event Deposited(address indexed user, uint256 indexed value, uint256 indexed amount, uint256 conversionRate);
    event OperatorSet(address indexed operator);

    address public immutable ethStrategy;
    address public operator;

    mapping(address => bool) public hasRedeemed;

    uint256 public immutable conversionPremium;
    bool public whiteListEnabled;

    uint256 private depositCap;

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not an operator");
        _;
    }

    /// @notice constructor
    /// @param _owner the owner of the deposit contract
    /// @param _ethStrategy the address of the ethstrategy token
    /// @param _operator the address of the operator
    /// @param _conversionRate the conversion rate from eth to ethstrategy
    /// @param _conversionPremium the conversion premium in basis points (0 - 100_00)
    /// @param _depositCap the maximum global deposit cap
    constructor(
        address _owner,
        address _ethStrategy,
        address _operator,
        uint256 _conversionRate,
        uint256 _conversionPremium,
        uint256 _depositCap,
        bool _whiteListEnabled
    ) {
        if (_conversionPremium > DENOMINATOR_BP) revert InvalidConversionPremium();
        CONVERSION_RATE = _conversionRate;
        _initializeOwner(_owner);
        ethStrategy = _ethStrategy;
        operator = _operator;
        conversionPremium = _conversionPremium;
        depositCap = _depositCap;
        whiteListEnabled = _whiteListEnabled;
    }

    /// @notice deposit flow and mint flow strategy
    function deposit() external payable nonReentrant returns (uint256) {
        uint256 value = msg.value;
        uint256 _depositCap = depositCap;
        if (value > _depositCap) revert DepositCapExceeded();
        depositCap = _depositCap - value;

        if (whiteListEnabled) {
            if (!isWhitelisted(msg.sender)) revert NotWhitelisted();

            if (hasRedeemed[msg.sender]) revert AlreadyRedeemed();
            hasRedeemed[msg.sender] = true;
        }

        if (value < MIN_DEPOSIT) revert DepositAmountTooLow();
        if (value > MAX_DEPOSIT) revert DepositAmountTooHigh();

        uint256 amount = msg.value * CONVERSION_RATE;
        amount = amount * (DENOMINATOR_BP - conversionPremium) / DENOMINATOR_BP;

        address payable recipient = payable(owner());
        (bool success,) = recipient.call{value: msg.value}("");
        if (!success) revert DepositFailed();

        IFlowStrategy(ethStrategy).mint(msg.sender, amount);
        emit Deposited(msg.sender, msg.value, amount, CONVERSION_RATE);
        return amount;
    }

    /// @notice get the current deposit cap
    /// @return the current deposit cap
    function getDepositCap() external view returns (uint256) {
        return depositCap;
    }

    /// @notice set the operator
    /// @param _operator the new operator
    /// @dev only the owner can set the operator
    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
        emit OperatorSet(_operator);
    }

    function setWhiteListEnabled(bool _whiteListEnabled) external onlyOperator {
        whiteListEnabled = _whiteListEnabled;
        emit WhiteListEnabledSet(_whiteListEnabled);
    }

    function addWhitelist(address[] memory _accounts) external onlyOperator {
        _addWhitelist(_accounts);
    }

    function removeWhitelist(address[] memory _accounts) external onlyOperator {
        _removeWhitelist(_accounts);
    }

    receive() external payable {
        revert InvalidCall();
    }
}
