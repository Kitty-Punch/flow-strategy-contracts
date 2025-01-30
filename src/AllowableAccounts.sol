// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract AllowableAccounts {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelist;

    error AccountAlreadyAdded(address account);
    error AccountNotAllowed(address account);
    error NoAccountsToAdd();
    error NoAccountsToRemove();
    error InvalidAccount(address account);
    error AccountNotFound(address account);

    event WhitelistedAdded(address[] indexed accounts);
    event WhitelistedRemoved(address[] indexed accounts);

    function _addWhitelist(address[] memory _accounts) internal virtual {
        if (_accounts.length == 0) revert NoAccountsToAdd();

        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_accounts[i] == address(0)) revert InvalidAccount(_accounts[i]);
            if (!_whitelist.add(_accounts[i])) revert AccountAlreadyAdded(_accounts[i]);
        }
        emit WhitelistedAdded(_accounts);
    }

    function _removeWhitelist(address[] memory _accounts) internal virtual {
        if (_accounts.length == 0) revert NoAccountsToRemove();

        for (uint256 i = 0; i < _accounts.length; i++) {
            if (!_whitelist.remove(_accounts[i])) revert AccountNotFound(_accounts[i]);
        }
        emit WhitelistedRemoved(_accounts);
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return _whitelist.contains(_account);
    }

    function getWhitelist() public view returns (address[] memory) {
        return _whitelist.values();
    }
}
