// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseERC721} from "./erc721/BaseERC721.sol";
import {IPremiumCalculator} from "../interfaces/options/IPremiumCalculator.sol";
import {ICallOption} from "../interfaces/options/ICallOption.sol";
import {IMintable} from "../interfaces/IMintable.sol";
import {ICallOptionFactory} from "../interfaces/options/ICallOptionFactory.sol";

contract CallOption is BaseERC721, ICallOption {
    using SafeERC20 for IERC20;

    // Mapping from token ID to Option details
    mapping(uint256 tokenId => Option optionInfo) internal _options;

    /// @notice The factory address
    address public factory;
    /// @notice The premium calculator address
    address public premiumCalculator;
    /// @notice The token that was paid to buy the option
    address public immutable paymentToken;
    /// @notice The minimum amount required for new options
    uint256 public immutable minAmount;
    /// @notice The strike price of the option
    uint256 public immutable strikePrice;
    /// @notice The expiration timestamp of the option
    uint256 public immutable expiration;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _premiumCalculator,
        address _paymentToken,
        uint256 _cap,
        uint256 _minAmount,
        uint256 _strikePrice,
        uint256 _expiration
    ) BaseERC721(_name, _symbol, _uri, _cap) {
        require(_premiumCalculator != address(0), "Premium calculator cannot be 0 address");
        require(_paymentToken != address(0), "Payment token cannot be 0 address");
        require(_strikePrice > 0, "Strike price must be positive");
        require(_expiration > block.timestamp, "Expiration must be in future");
        factory = msg.sender;
        premiumCalculator = _premiumCalculator;
        paymentToken = _paymentToken;
        minAmount = _minAmount;
        strikePrice = _strikePrice;
        expiration = _expiration;
    }

    function buyCallOption(uint256 _amount) external returns (uint256 optionId) {
        require(_amount >= minAmount, "Amount must be gt min amount");
        require(block.timestamp < expiration, "Option expired");

        address _user = msg.sender;

        uint256 premiumPaid = IPremiumCalculator(premiumCalculator).getPremium(_amount, strikePrice, expiration);
        require(premiumPaid > 0, "Premium must be greater than 0");
        IERC20(paymentToken).safeTransferFrom(_user, _treasury(), premiumPaid);

        optionId = _mintToken(_user);

        _options[optionId] = Option({premiumPaid: premiumPaid, amount: _amount, exercised: false});

        emit OptionBought(_user, optionId, _amount, strikePrice, expiration, premiumPaid);
    }

    function exerciseOption(uint256 optionId) external returns (uint256 amountBought, uint256 totalStrikeCost) {
        address _user = msg.sender;
        require(block.timestamp < expiration, "Option expired");
        require(ownerOf(optionId) == _user, "User is not the owner of the option");
        require(!_options[optionId].exercised, "Option already exercised");

        Option storage option = _options[optionId];

        option.exercised = true;
        totalStrikeCost = uint256(option.amount) * strikePrice;

        // Transfer strike price payment from the user to the treasury.
        IERC20(paymentToken).safeTransferFrom(_user, _treasury(), totalStrikeCost);

        // Mint tokens to the user.
        IMintable(_underlyingToken()).mint(_user, option.amount);

        emit OptionExercised(optionId, option.amount, totalStrikeCost);

        return (option.amount, totalStrikeCost);
    }

    function getOption(uint256 tokenId) external view returns (Option memory) {
        return _options[tokenId];
    }

    function getOptions(address _owner) external view returns (Option[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        Option[] memory tokens = new Option[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = _options[tokenOfOwnerByIndex(_owner, i)];
        }
        return tokens;
    }

    function _batchMint(address, uint256) internal pure override returns (uint256[] memory) {
        revert("Batch minting not implemented");
    }

    function _treasury() internal view returns (address) {
        return ICallOptionFactory(factory).treasury();
    }

    function _underlyingToken() internal view returns (address) {
        return ICallOptionFactory(factory).underlyingToken();
    }
}
