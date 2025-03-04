// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ICallOption is IERC721, IERC721Metadata {
    struct Option {
        uint256 premiumPaid;
        uint256 amount;
        bool exercised;
    }

    event OptionBought(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed amount,
        uint256 strikePrice,
        uint256 expiration,
        uint256 premiumPaid
    );

    event OptionExercised(uint256 indexed tokenId, uint256 indexed amountBought, uint256 indexed totalStrikeCost);

    /// @notice The payment token address used to buy options
    function paymentToken() external view returns (address);

    /// @notice The factory address
    function factory() external view returns (address);

    /// @notice The premium calculator address
    function premiumCalculator() external view returns (address);

    /// @notice The minimum amount required for new options
    function minAmount() external view returns (uint256);

    /// @notice The strike price of the option
    function strikePrice() external view returns (uint256);

    /// @notice The expiration timestamp of the option
    function expiration() external view returns (uint256);

    /// @notice Get option details for a specific token ID
    /// @param tokenId The ID of the option token
    /// @return Option struct containing the option details
    function getOption(uint256 tokenId) external view returns (Option memory);

    /// @notice Get all options owned by an address
    /// @param _owner The address to query options for
    /// @return An array of Option structs
    function getOptions(address _owner) external view returns (Option[] memory);

    /// @notice Creates a new option token
    /// @param _amount Amount of underlying tokens
    /// @return optionId The ID of the newly created option token
    function buyCallOption(uint256 _amount) external returns (uint256 optionId);

    /// @notice Exercise an option
    /// @param tokenId The ID of the option to exercise
    /// @return amountBought The amount of underlying tokens bought
    /// @return totalStrikeCost The total strike cost of the option
    function exerciseOption(uint256 tokenId) external returns (uint256 amountBought, uint256 totalStrikeCost);
}
