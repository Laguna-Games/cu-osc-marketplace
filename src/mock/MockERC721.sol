// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC721Royalty, ERC721} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';

contract MockERC721 is ERC721Royalty, Ownable {
    constructor() ERC721('MyToken', 'MTK') Ownable() {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}
