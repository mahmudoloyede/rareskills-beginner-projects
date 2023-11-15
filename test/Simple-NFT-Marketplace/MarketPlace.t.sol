// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MarketPlace} from "../../src/Simple-NFT-Marketplace/MarketPlace.sol";
import {Sample} from "./Sample-NFT.sol";

contract MarketPlaceTest is Test {
    Sample public nft1;
    Sample public nft2;
    MarketPlace public market;

    function setUp() public {
        nft1 = new Sample();
        nft2 = new Sample();
        market = new MarketPlace();
    }

    function testSellFailsIfNotOwnerOfNFT() public {
        vm.prank(address(123));
        nft1.mint(456);
        vm.expectRevert("Not Owner of NFT");
        market.sell(address(nft1), 456, 3 ether, 5 days);
    }

    function testSellFailsIfMarketPlaceNotApproved() public {
        nft1.mint(456);
        vm.expectRevert("Approve Contract First");
        market.sell(address(nft1), 456, 3 ether, 5 days);
    }

    function testSell() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        (
            address seller,
            address tokenAddress,
            uint256 tokenId,
            uint256 price,
            uint256 deadline,
            bool cancelled,
            bool sold
        ) = market.listings(0);
        assertEq(seller, address(this));
        assertEq(tokenAddress, address(nft1));
        assertEq(tokenId, 123);
        assertEq(price, 5 ether);
        assertEq(deadline, block.timestamp + 10 days);
        assertFalse(cancelled);
        assertFalse(sold);
        vm.startPrank(address(345));
        nft2.mint(789);
        nft2.approve(address(market), 789);
        market.sell(address(nft2), 789, 3 ether, 5 days);
        vm.stopPrank();
        (seller, tokenAddress, tokenId, price, deadline, cancelled, sold) = market.listings(1);
        assertEq(seller, address(345));
        assertEq(tokenAddress, address(nft2));
        assertEq(tokenId, 789);
        assertEq(price, 3 ether);
        assertEq(deadline, block.timestamp + 5 days);
        assertFalse(cancelled);
        assertFalse(sold);
    }

    function testSellFailsIfNFTAlreadyListed() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.warp(block.timestamp + 5 days);
        vm.expectRevert("NFT already listed");
        market.sell(address(nft1), 123, 20 ether, 4 days);
    }

    function testBuyFailsWithInvalidID() public {
        vm.startPrank(address(123));
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.stopPrank();
        vm.expectRevert("Invalid List ID");
        market.buy(1);
    }

    function testBuyFailsWhenValueTooSmall() public {
        vm.startPrank(address(123));
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.stopPrank();
        vm.expectRevert("Value too small");
        market.buy{value: 3 ether}(0);
    }

    function testBuyFailsWhenListingCancelled() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.warp(block.timestamp + 7 days);
        market.cancel(0);
        startHoax(address(123), 5 ether);
        vm.expectRevert("Listing cancelled or deadline reached");
        market.buy{value: 5 ether}(0);
        vm.stopPrank();
    }

    function testBuyFailsWhenDeadlineReached() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.warp(block.timestamp + 10 days);
        startHoax(address(123), 5 ether);
        vm.expectRevert("Listing cancelled or deadline reached");
        market.buy{value: 5 ether}(0);
        vm.stopPrank();
    }

    function testBuyFailsWhenAlreadySold() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        startHoax(address(123), 5 ether);
        market.buy{value: 5 ether}(0);
        vm.stopPrank();
        vm.warp(block.timestamp + 5 days);
        startHoax(address(345), 5 ether);
        vm.expectRevert("Listing Sold");
        market.buy{value: 5 ether}(0);
        vm.stopPrank();
    }

    function testBuy() public {
        uint256 sellerBalance = address(this).balance;
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        (,,,,,, bool sold) = market.listings(0);
        assertFalse(sold);
        startHoax(address(123), 5 ether);
        market.buy{value: 5 ether}(0);
        vm.stopPrank();
        (,,,,,, sold) = market.listings(0);
        assertEq(nft1.ownerOf(123), address(123));
        assertEq(address(this).balance, sellerBalance + 5 ether);
        assertTrue(sold);
    }

    function testCancelFailsWithInvalidID() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.expectRevert("Invalid List ID");
        market.cancel(1);
    }

    function testCancelFailsWhenNotSeller() public {
        vm.startPrank(address(345));
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.stopPrank();
        vm.expectRevert("Not NFT Seller");
        market.cancel(0);
    }

    function testCancelFailsAtDeadline() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        vm.warp(10 days + block.timestamp);
        vm.expectRevert("Deadline Reached");
        market.cancel(0);
    }

    function testCancel() public {
        nft1.mint(123);
        nft1.approve(address(market), 123);
        market.sell(address(nft1), 123, 5 ether, 10 days);
        (,,,,, bool cancelled,) = market.listings(0);
        assertFalse(cancelled);
        assertTrue(market.listed(address(nft1), 123));
        vm.warp(5 days + block.timestamp);
        market.cancel(0);
        (,,,,, cancelled,) = market.listings(0);
        assertTrue(cancelled);
        assertFalse(market.listed(address(nft1), 123));
    }

    receive() external payable {}
}
