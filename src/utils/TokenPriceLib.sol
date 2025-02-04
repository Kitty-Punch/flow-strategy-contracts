// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library TokenPriceLib {
    uint256 constant DEFAULT_TOKEN_DECIMALS = 18;

    // Price decimals are the decimals of the purchase token.
    // Purchase token decimals is 18.
    function _normalize(uint256 _price, uint256 _amount, address _paymentToken) internal view returns (uint256) {
        return _normalize(
            _price,
            _amount,
            IERC20Metadata(_paymentToken).decimals(), // Price decimals
            IERC20Metadata(_paymentToken).decimals(), // Payment token decimals
            DEFAULT_TOKEN_DECIMALS // Purchase token decimals
        );
    }

    // Price decimals are the decimals of the purchase token.
    function _normalize(uint256 _price, uint256 _amount, address _paymentToken, address _purchaseToken)
        internal
        view
        returns (uint256)
    {
        return _normalize(_price, _amount, IERC20Metadata(_paymentToken).decimals(), _paymentToken, _purchaseToken);
    }

    function _normalize(
        uint256 _price,
        uint256 _amount,
        uint256 _priceDecimals,
        address _paymentToken,
        address _purchaseToken
    ) internal view returns (uint256) {
        return _normalize(
            _price,
            _amount,
            _priceDecimals,
            IERC20Metadata(_paymentToken).decimals(),
            IERC20Metadata(_purchaseToken).decimals()
        );
    }

    function _normalize(
        uint256 _price,
        uint256 _amount,
        uint256 _priceDecimals,
        uint256 _paymentTokenDecimals,
        uint256 _purchaseTokenDecimals
    ) internal pure returns (uint256) {
        uint256 paymentTokenDecimals = _paymentTokenDecimals;
        uint256 priceDecimals = _priceDecimals;
        uint256 purchaseTokenDecimals = _purchaseTokenDecimals;
        uint256 decimalsDifference;

        if (purchaseTokenDecimals >= priceDecimals) {
            decimalsDifference = purchaseTokenDecimals - priceDecimals;
            _price = _price * (10 ** decimalsDifference);
        } else {
            decimalsDifference = priceDecimals - purchaseTokenDecimals;
            _price = _price / (10 ** decimalsDifference);
        }

        uint256 finalPrice = _price * _amount;

        if (paymentTokenDecimals >= purchaseTokenDecimals) {
            decimalsDifference = paymentTokenDecimals - purchaseTokenDecimals;
            finalPrice = finalPrice * (10 ** decimalsDifference);
        } else {
            decimalsDifference = purchaseTokenDecimals - paymentTokenDecimals;
            finalPrice = finalPrice / (10 ** decimalsDifference);
        }

        return finalPrice / (10 ** purchaseTokenDecimals);
    }
}
