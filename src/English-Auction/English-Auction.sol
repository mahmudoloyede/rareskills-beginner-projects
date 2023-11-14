// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "./IERC721.sol";

contract EnglishAuction {
    struct Auction {
        address seller;
        address winner;
        address token;
        uint256 tokenId;
        uint256 reservePrice;
        uint256 deadline;
        uint256 winningBid;
    }

    Auction[] public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    function deposit(address _token, uint256 _tokenId, uint256 _reservePrice, uint256 _deadline) external {
        IERC721 nft = IERC721(_token);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not Owner of NFT!");
        nft.transferFrom(msg.sender, address(this), _tokenId);
        auctions.push(Auction(msg.sender, address(0), _token, _tokenId, _reservePrice, block.timestamp + _deadline, 0));
    }

    function bid(uint256 id) external payable {
        require(auctions.length > id, "No Such Auction");
        Auction storage auction = auctions[id];
        require(auction.deadline > block.timestamp, "Auction Ended");
        require(msg.value > auction.winningBid && msg.value >= auction.reservePrice, "Bid too small");
        if (auction.winner != address(0)) {
            bids[id][auction.winner] += auction.winningBid;
        }
        auction.winner = msg.sender;
        auction.winningBid = msg.value;
    }

    function withdrawBid(uint256 id) external {
        require(auctions.length > id, "No Such Auction");
        Auction storage auction = auctions[id];
        require(block.timestamp >= auction.deadline, "Wait till deadline to withdraw bids");
        uint256 bidAmount = bids[id][msg.sender];
        bids[id][msg.sender] = 0;
        (bool success,) = msg.sender.call{value: bidAmount}("");
        require(success, "Call Failed!");
    }

    function sellerEndAuction(uint256 id) external {
        require(auctions.length > id, "No Such Auction");
        Auction storage auction = auctions[id];
        IERC721 nft = IERC721(auction.token);
        require(msg.sender == auction.seller, "Not Seller!");
        require(block.timestamp >= auction.deadline, "Deadline not reached");
        if (auction.winner != address(0)) {
            nft.transferFrom(address(this), auction.winner, auction.tokenId);
            (bool success,) = msg.sender.call{value: auction.winningBid}("");
            require(success);
        } else {
            nft.transferFrom(address(this), auction.seller, auction.tokenId);
        }
    }
}
