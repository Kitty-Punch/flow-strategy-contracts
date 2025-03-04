// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract BaseERC721 is ERC721Enumerable, ERC721Burnable {
    uint256 public constant NOT_CAP = 0;

    // Maximum number of tokens that can be minted. Use 0 for unlimited.
    uint256 public immutable CAP;

    // Counter for the next token id to be minted. Since it starts from 0, it's the total number of tokens minted.
    uint256 private _tokenIdCounter;

    string public baseURI;

    event BaseURISet(string uri);

    modifier leThanCap(uint256 _quantity) {
        /*
        Example 1: Ok
        _tokenIdCounter = 3 (current 3 tokens including 0 index)
        _quantity = 2 (new tokens)
        cap = 5

        Example 2: Not Ok
        _tokenIdCounter = 3 (current 3 tokens including 0 index)
        _quantity = 2 (new tokens)
        cap = 4
        */
        require(CAP == NOT_CAP || _tokenIdCounter + _quantity <= CAP, "Cap exceeded");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _uri, uint256 _cap)
        ERC721(_name, _symbol)
    {
        baseURI = _uri;
        CAP = _cap;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Enumerable, ERC721)
        returns (address)
    {
        return ERC721Enumerable._update(to, tokenId, auth);
    }

    // slither-disable-next-line dead-code
    function _increaseBalance(address account, uint128 value) internal override(ERC721Enumerable, ERC721) {
        ERC721Enumerable._increaseBalance(account, value);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _mintToken(address _sender) internal virtual leThanCap(1) returns (uint256) {
        uint256 newTokenId = _tokenIdCounter;

        // Mint the token
        _safeMint(_sender, newTokenId);

        _tokenIdCounter += 1;

        return newTokenId;
    }

    function _batchMint(address _sender, uint256 _quantity)
        internal
        virtual
        leThanCap(_quantity)
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 newTokenId = _tokenIdCounter;

            _safeMint(_sender, newTokenId);

            _tokenIdCounter += 1;
            tokenIds[i] = newTokenId;
        }
    }

    function _setBaseURI(string memory _uri) internal virtual {
        baseURI = _uri;
        emit BaseURISet(_uri);
    }
}
