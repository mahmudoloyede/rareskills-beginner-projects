// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "./IERC721.sol";

contract MarketPlace {
    struct NFT {
        address seller;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
        bool cancelled;
        bool sold;
    }

    NFT[] public listings;
    mapping(address => mapping(uint256 => bool)) public listed;

    function sell(address _tokenAddress, uint256 _tokenId, uint256 _price, uint256 _deadline) external {
        IERC721 nft = IERC721(_tokenAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not Owner of NFT");
        require(nft.getApproved(_tokenId) == address(this), "Approve Contract First");
        require(!listed[_tokenAddress][_tokenId], "NFT already listed");
        listings.push(NFT(msg.sender, _tokenAddress, _tokenId, _price, block.timestamp + _deadline, false, false));
        listed[_tokenAddress][_tokenId] = true;
    }

    function buy(uint256 id) external payable {
        require(listings.length > id, "Invalid List ID");
        NFT storage nftList = listings[id];
        require(msg.value >= nftList.price, "Value too small");
        require(!nftList.cancelled && block.timestamp < nftList.deadline, "Listing cancelled or deadline reached");
        require(!nftList.sold, "Listing Sold");
        IERC721 nft = IERC721(nftList.tokenAddress);
        // require(nft.getApproved(nftList.tokenId) == address(this), "Approve Contract First");
        nft.transferFrom(nftList.seller, msg.sender, nftList.tokenId);
        (bool success,) = nftList.seller.call{value: msg.value}("");
        require(success);
        nftList.sold = true;
    }

    function cancel(uint256 id) external {
        require(listings.length > id, "Invalid List ID");
        NFT storage nftList = listings[id];
        require(msg.sender == nftList.seller, "Not NFT Seller");
        require(nftList.deadline > block.timestamp, "Deadline Reached");
        nftList.cancelled = true;
        listed[nftList.tokenAddress][nftList.tokenId] = false;
    }
}
