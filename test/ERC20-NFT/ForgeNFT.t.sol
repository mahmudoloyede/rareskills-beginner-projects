// SPDX-License-Identifier: MI
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Forge} from "./ForgeToken.sol";
import {ForgeNFT} from "../../src/ERC20-NFT/ForgeNFT.sol";

contract ForgeNFTTest is Test {
    Forge public forge;
    ForgeNFT public forgeNft;

    function setUp() public {
        forge = new Forge();
        forgeNft = new ForgeNFT(address(forge));
    }

    function testNameAndSymbol() public {
        assertEq(forgeNft.name(), "ForgeNFT");
        assertEq(forgeNft.symbol(), "FN");
    }

    function testMintRevertWhenNoAllowance() public {
        vm.expectRevert();
        forgeNft.mint();
    }

    function testMint() public {
        uint256 tokenId = forgeNft.totalSupply();
        uint256 price = forgeNft.PRICE();
        forge.mint{value: 0.5 ether}();
        forge.approve(address(forgeNft), price);
        forgeNft.mint();
        assertEq(forgeNft.totalSupply(), tokenId + 1);
        assertEq(forgeNft.ownerOf(tokenId), address(this));
    }
}
