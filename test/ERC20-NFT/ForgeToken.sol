// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Forge is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 10 ether;

    constructor() ERC20("Forge", "FG") {}

    function mint() public payable {
        uint256 amount = msg.value * 10;
        _mint(msg.sender, amount);
        require(totalSupply() < TOTAL_SUPPLY, "Total Supply Reached!");
    }
}
