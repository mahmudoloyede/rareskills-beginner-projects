// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Sample} from "../../src/NFT-Swap-Contract/Sample-NFT.sol";
import {Swapper} from "../../src/NFT-Swap-Contract/NFT-Swap-Contract.sol";

contract SwapperTest is Test {
    Sample public nft1;
    Sample public nft2;
    Swapper public swapper;

    function setUp() public {
        nft1 = new Sample();
        nft2 = new Sample();
        swapper = new Swapper();
    }

    function testCreateSwapRevertsWhenCreated() public {
        // make swapCreated bool true
        vm.store(
            address(swapper), bytes32(uint256(6)), 0x0000000000000000000000010000000000000000000000000000000000000000
        );
        vm.expectRevert("Swap Created!");
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
    }

    function testCreateSwap() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        assertEq(swapper.token1(), address(nft1));
        assertEq(swapper.token2(), address(nft2));
        assertEq(swapper.tokenId1(), 2);
        assertEq(swapper.tokenId2(), 3);
        assertTrue(swapper.swapCreated());
    }

    function testDepositToken1RevertsIfSwapNotCreated() public {
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        vm.expectRevert("Create Swap First");
        swapper.depositToken1();
    }

    function testDepositToken1RevertsIfNotOwner() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xbad));
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        vm.stopPrank();
        vm.expectRevert("Not Owner of NFT!");
        swapper.depositToken1();
    }

    function testDepositToken1() public {
        vm.warp(12345);
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xbad));
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        swapper.depositToken1();
        vm.stopPrank();
        assertEq(nft1.ownerOf(2), address(swapper));
        assertEq(swapper.token2Receiver(), address(0xbad));
        assertEq(swapper.lastTokenDepositTime(), 12345);
    }

    function testDepositToken2RevertsIfSwapNotCreated() public {
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        vm.expectRevert("Create Swap First");
        swapper.depositToken2();
    }

    function testDepositToken2RevertsIfNotOwner() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xdead));
        nft2.mint(3);
        nft2.approve(address(swapper), 3);
        vm.stopPrank();
        vm.expectRevert("Not Owner of NFT!");
        swapper.depositToken2();
    }

    function testDepositToken2() public {
        vm.warp(67890);
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xdead));
        nft2.mint(3);
        nft2.approve(address(swapper), 3);
        swapper.depositToken2();
        vm.stopPrank();
        assertEq(nft2.ownerOf(3), address(swapper));
        assertEq(swapper.token1Receiver(), address(0xdead));
        assertEq(swapper.lastTokenDepositTime(), 67890);
    }

    function testSwapFailsWhenNoNFTDeposited() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        nft1.mint(2);
        nft2.mint(3);
        vm.expectRevert("NFTs not deposited");
        swapper.swap();
    }

    function testSwapFailsIfNFT1NotDeposited() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        nft1.mint(2);
        vm.startPrank(address(0xdead));
        nft2.mint(3);
        nft2.approve(address(swapper), 3);
        swapper.depositToken2();
        vm.stopPrank();
        vm.expectRevert("NFTs not deposited");
        swapper.swap();
    }

    function testSwapFailsIfNFT2NotDeposited() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        nft2.mint(3);
        vm.startPrank(address(0xbad));
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        swapper.depositToken1();
        vm.stopPrank();
        vm.expectRevert("NFTs not deposited");
        swapper.swap();
    }

    function testSwapFailsIfNot30MinsAfterLastDeposit() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xbad));
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        swapper.depositToken1();
        vm.stopPrank();
        vm.warp(12345);
        vm.startPrank(address(0xdead));
        nft2.mint(3);
        nft2.approve(address(swapper), 3);
        swapper.depositToken2();
        vm.stopPrank();
        vm.expectRevert("Wait 30 minutes after last deposit to swap");
        swapper.swap();
    }

    function testSwap() public {
        swapper.createSwap(address(nft1), address(nft2), 2, 3);
        vm.startPrank(address(0xbad));
        nft1.mint(2);
        nft1.approve(address(swapper), 2);
        swapper.depositToken1();
        vm.stopPrank();
        vm.warp(12345);
        vm.startPrank(address(0xdead));
        nft2.mint(3);
        nft2.approve(address(swapper), 3);
        swapper.depositToken2();
        vm.stopPrank();
        vm.warp(12345 + 30 minutes);
        swapper.swap();
        assertEq(nft1.ownerOf(2), address(0xdead));
        assertEq(nft2.ownerOf(3), address(0xbad));
        assertFalse(swapper.swapCreated());
    }
}
