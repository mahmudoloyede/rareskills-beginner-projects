// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Forge} from "./ForgeToken.sol";

contract ForgeNFT is ERC721 {
    uint256 public totalSupply;
    uint256 public constant PRICE = 0.01 ether;
    Forge public forge;

    constructor(address _forge) ERC721("ForgeNFT", "FN") {
        forge = Forge(_forge);
    }

    function mint() public {
        require(forge.transferFrom(msg.sender, address(this), PRICE), "transfer failed!");
        uint256 tokenId = totalSupply++;
        _mint(msg.sender, tokenId);
        // _safeMint(msg.sender, tokenId);
    }
}
