// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Forge} from "../../src/ERC20-NFT/ForgeToken.sol";

contract ForgeTest is Test {
    Forge public forge;

    function setUp() public {
        forge = new Forge();
    }

    // function testTOTAL_SUPPLY() public {
    //   assertEq(forge.TOTAL_SUPPLY(), 10 ether);
    // }

    function testNameAndSymbol() public {
        assertEq(forge.name(), "Forge");
        assertEq(forge.symbol(), "FG");
    }

    function testMintRevertWhenTotalSupplyReached() public {
        vm.expectRevert("Total Supply Reached!");
        forge.mint{value: 1 ether}();
    }

    function testMint() public {
        uint256 total = forge.totalSupply();
        uint256 forgeBalanceBeforeMint = forge.balanceOf(address(this));
        uint256 amount = 0.5 ether;
        forge.mint{value: amount}();
        assertEq(forge.totalSupply(), total + (amount * 10));
        assertEq(forge.balanceOf(address(this)), forgeBalanceBeforeMint + (amount * 10));
    }
}
