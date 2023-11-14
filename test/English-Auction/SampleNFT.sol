// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Sample is ERC721 {
    constructor() ERC721("Sample", "ST") {}

    function mint(uint256 Id) public {
        _mint(msg.sender, Id);
    }
}
