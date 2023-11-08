// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISample} from "./ISample-NFT.sol";

contract Swapper {
    uint256 public tokenId1;
    uint256 public tokenId2;
    uint256 public lastTokenDepositTime;
    address public token1;
    address public token2;
    address public token1Receiver;
    address public token2Receiver;
    bool public swapCreated;

    function createSwap(address _token1, address _token2, uint256 id1, uint256 id2) external {
        require(!swapCreated, "Swap Created!");
        token1 = _token1;
        token2 = _token2;
        tokenId1 = id1;
        tokenId2 = id2;
        swapCreated = true;
    }

    function depositToken1() external {
        require(swapCreated, "Create Swap First");
        ISample nft = ISample(token1);
        require(nft.ownerOf(tokenId1) == msg.sender, "Not Owner of NFT!");
        nft.transferFrom(msg.sender, address(this), tokenId1);
        token2Receiver = msg.sender;
        lastTokenDepositTime = block.timestamp;
    }

    function depositToken2() external {
        require(swapCreated, "Create Swap First");
        ISample nft = ISample(token2);
        require(nft.ownerOf(tokenId2) == msg.sender, "Not Owner of NFT!");
        nft.transferFrom(msg.sender, address(this), tokenId2);
        token1Receiver = msg.sender;
        lastTokenDepositTime = block.timestamp;
    }

    function swap() public {
        ISample nft1 = ISample(token1);
        ISample nft2 = ISample(token2);
        require(
            nft1.ownerOf(tokenId1) == address(this) && nft2.ownerOf(tokenId2) == address(this), "NFTs not deposited"
        );
        require(block.timestamp >= lastTokenDepositTime + 30 minutes, "Wait 30 minutes after last deposit to swap");
        nft1.transferFrom(address(this), token1Receiver, tokenId1);
        nft2.transferFrom(address(this), token2Receiver, tokenId2);
        swapCreated = false;
    }
}
