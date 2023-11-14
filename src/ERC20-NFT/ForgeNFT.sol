// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "./IERC20.sol";

contract ForgeNFT is ERC721 {
    uint256 public totalSupply;
    uint256 public constant PRICE = 0.01 ether;
    address public tokenAddress;

    constructor(address _tokenAddress) ERC721("ForgeNFT", "FN") {
        tokenAddress = _tokenAddress;
    }

    function mint() public {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), PRICE);
        uint256 tokenId = totalSupply++;
        _mint(msg.sender, tokenId);
    }
}
