// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EnglishAuction} from "../../src/English-Auction/English-Auction.sol";
import {Sample} from "./SampleNFT.sol";

contract EnglishAuctionTest is Test {
    EnglishAuction public auction;
    Sample public nft1;
    Sample public nft2;

    function setUp() public {
        nft1 = new Sample();
        nft2 = new Sample();
        auction = new EnglishAuction();
    }

    function testDepositFailsIfNotOwnerOfNFT() public {
        vm.prank(address(123));
        nft1.mint(1);
        vm.expectRevert("Not Owner of NFT!");
        auction.deposit(address(nft1), 1, 2 ether, 5 days);
    }

    function testDeposit() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        assertEq(nft1.ownerOf(123), address(auction));
        (
            address seller,
            address winner,
            address token,
            uint256 tokenId,
            uint256 reservePrice,
            uint256 deadline,
            uint256 winningBid
        ) = auction.auctions(0);
        assertEq(seller, address(this));
        assertEq(winner, address(0));
        assertEq(token, address(nft1));
        assertEq(tokenId, 123);
        assertEq(reservePrice, 5 ether);
        assertEq(deadline, 3 days + block.timestamp);
        assertEq(winningBid, 0);
        vm.warp(123456);
        vm.startPrank(address(0xbad));
        nft2.mint(456);
        nft2.approve(address(auction), 456);
        auction.deposit(address(nft2), 456, 10 ether, 10 days);
        vm.stopPrank();
        (seller, winner, token, tokenId, reservePrice, deadline, winningBid) = auction.auctions(1);
        assertEq(seller, address(0xbad));
        assertEq(winner, address(0));
        assertEq(token, address(nft2));
        assertEq(tokenId, 456);
        assertEq(reservePrice, 10 ether);
        assertEq(deadline, 10 days + 123456);
        assertEq(winningBid, 0);
    }

    function testBidFailsWithInvalidID() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.expectRevert("No Such Auction");
        auction.bid(1);
    }

    function testBidFailsAtDeadline() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.warp(3 days + block.timestamp);
        vm.expectRevert("Auction Ended");
        auction.bid(0);
    }

    function testBidFailsWhenBidAmountTooSmall() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.expectRevert("Bid too small");
        auction.bid{value: 4 ether}(0);

        auction.bid{value: 7 ether}(0);
        vm.expectRevert("Bid too small");
        auction.bid{value: 6 ether}(0);
    }

    function testBid() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        hoax(address(0xdead), 7 ether);
        auction.bid{value: 7 ether}(0);
        (, address winner,,,,, uint256 winningBid) = auction.auctions(0);
        assertEq(winner, address(0xdead));
        assertEq(winningBid, 7 ether);
        assertEq(auction.bids(0, address(0xdead)), 0 ether);
        hoax(address(0xdeed), 10 ether);
        auction.bid{value: 10 ether}(0);
        (, winner,,,,, winningBid) = auction.auctions(0);
        assertEq(winner, address(0xdeed));
        assertEq(winningBid, 10 ether);
        assertEq(auction.bids(0, address(0xdead)), 7 ether);
        assertEq(auction.bids(0, address(0xdeed)), 0);
    }

    function testWithdrawBidFailsWithInvalidID() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.expectRevert("No Such Auction");
        auction.withdrawBid(1);
    }

    function testWithdrawBidFailsWhenNotDeadline() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.warp(1 days);
        vm.expectRevert("Wait till deadline to withdraw bids");
        auction.withdrawBid(0);
    }

    function testWithdrawBid() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        hoax(address(0xdead), 7 ether);
        auction.bid{value: 7 ether}(0);
        hoax(address(0xdeed), 10 ether);
        auction.bid{value: 10 ether}(0);
        hoax(address(0xfeed), 12 ether);
        auction.bid{value: 12 ether}(0);
        uint256 deadWithrawableBid = auction.bids(0, address(0xdead));
        uint256 deedWithrawableBid = auction.bids(0, address(0xdeed));
        // console.log(deadWithrawableBid);
        // console.log(deedWithrawableBid);
        // uint feedWithrawableBid = auction.bids(0, address(0xfeed));
        // console.log(feedWithrawableBid);
        vm.warp(4 days);
        vm.prank(address(0xdead));
        auction.withdrawBid(0);
        vm.prank(address(0xdeed));
        auction.withdrawBid(0);
        // vm.prank(address(0xfeed));
        // auction.withdrawBid(0);
        assertEq(address(0xdead).balance, deadWithrawableBid);
        assertEq(address(0xdeed).balance, deedWithrawableBid);
        // assertEq(address(0xfeed).balance, feedWithrawableBid);
        assertEq(auction.bids(0, address(0xdead)), 0);
        assertEq(auction.bids(0, address(0xdeed)), 0);
    }

    function testSellerEndAuctionFailsWithInvalidID() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.expectRevert("No Such Auction");
        auction.sellerEndAuction(1);
    }

    function testSellerEndAuctionFailsWhenNotSeller() public {
        vm.startPrank(address(123));
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.stopPrank();
        vm.expectRevert("Not Seller!");
        auction.sellerEndAuction(0);
    }

    function testSellerEndAuctionFailsWhenNotDeadline() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        vm.warp(1 days);
        vm.expectRevert("Deadline not reached");
        auction.sellerEndAuction(0);
    }

    function testSellerEndAuctionWhenReserveMet() public {
        uint256 balBefore = address(this).balance;
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        hoax(address(0xdead), 7 ether);
        auction.bid{value: 7 ether}(0);
        vm.warp(4 days);
        auction.sellerEndAuction(0);
        assertEq(nft1.ownerOf(123), address(0xdead));
        assertEq(address(this).balance, balBefore + 7 ether);
    }

    function testSellerEndAuctionWhenReserveNotMet() public {
        nft1.mint(123);
        nft1.approve(address(auction), 123);
        auction.deposit(address(nft1), 123, 5 ether, 3 days);
        assertEq(nft1.ownerOf(123), address(auction));
        vm.warp(4 days);
        auction.sellerEndAuction(0);
        assertEq(nft1.ownerOf(123), address(this));
    }

    receive() external payable {}
}
