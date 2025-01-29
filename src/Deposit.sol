pragma solidity 0.8.25;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IFlowStrategy} from "./interfaces/IFlowStrategy.sol";
import {SignatureCheckerLib} from "solady/src/utils/SignatureCheckerLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Deposit is Ownable, ReentrancyGuard {

  uint256 public immutable CONVERSION_RATE;
  uint256 constant MIN_DEPOSIT = 1e18;
  uint256 constant MAX_DEPOSIT = 100e18;

  error DepositAmountTooLow();
  error DepositAmountTooHigh();
  error DepositFailed();
  error AlreadyRedeemed();
  error DepositCapExceeded();
  error InvalidConversionPremium();
  error InvalidSignature();
  error InvalidCall();

  address public immutable ethStrategy;
  address public signer;

  mapping(address => bool) public hasRedeemed;

  uint256 public immutable conversionPremium;
    bool public immutable whiteListEnabled;
  uint256 public constant DENOMINATOR_BP = 100_00;

  uint256 private depositCap_;

  /// @notice constructor
  /// @param _owner the owner of the deposit contract
  /// @param _ethStrategy the address of the ethstrategy token
  /// @param _signer the address of the signer
  /// @param _conversionRate the conversion rate from eth to ethstrategy
  /// @param _conversionPremium the conversion premium in basis points (0 - 100_00)
  /// @param _depositCap the maximum global deposit cap
  constructor(address _owner, address _ethStrategy, address _signer, uint256 _conversionRate,uint256 _conversionPremium, uint256 _depositCap, bool _whiteListEnabled) {
    if(_conversionPremium > DENOMINATOR_BP) revert InvalidConversionPremium();
    CONVERSION_RATE = _conversionRate;
    _initializeOwner(_owner);
    ethStrategy = _ethStrategy;
    signer = _signer;
    conversionPremium = _conversionPremium;
    depositCap_ = _depositCap;
    whiteListEnabled = _whiteListEnabled;
  }

  /// @notice deposit eth and mint ethstrategy
  /// @param signature the signature of the signer for the depositor
  function deposit(bytes calldata signature) external payable nonReentrant {
    uint256 value = msg.value;
    uint256 _depositCap = depositCap_;
    if (value > _depositCap) revert DepositCapExceeded();
    depositCap_ = _depositCap - value;

    if (whiteListEnabled) {
      if (hasRedeemed[msg.sender]) revert AlreadyRedeemed();
      hasRedeemed[msg.sender] = true;

      bytes32 hash = keccak256(abi.encodePacked(msg.sender));
      if (!SignatureCheckerLib.isValidSignatureNow(signer, hash, signature)) revert InvalidSignature();
    }

    if (value < MIN_DEPOSIT) revert DepositAmountTooLow();
    if (value > MAX_DEPOSIT) revert DepositAmountTooHigh();

    uint256 amount = msg.value * CONVERSION_RATE;
    amount = amount * (DENOMINATOR_BP - conversionPremium) / DENOMINATOR_BP;

    address payable recipient = payable(owner());
    (bool success, ) = recipient.call{value: msg.value}("");
    if (!success) revert DepositFailed();

    IFlowStrategy(ethStrategy).mint(msg.sender, amount);
  }

  /// @notice get the current deposit cap
  /// @return the current deposit cap
  function depositCap() external view returns (uint256) {
    return depositCap_;
  }

  /// @notice set the signer
  /// @param _signer the new signer
  /// @dev only the owner can set the signer
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  receive() external payable {
    revert InvalidCall();
  }
}