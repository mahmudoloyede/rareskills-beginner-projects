// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract SimpleLottery {
    error InvalidBlockNumber();
    error InvalidLotteryId();
    error DeadlineReached();
    error ValueTooSmall();
    error ExceedBlockHashLimit(uint256 blockNumber);
    error WithinBlockHashLimit(uint256 blockNumber);
    error LotteryNotOver(uint256 id);
    error LotteryClaimed(uint256 id);
    error NotParticipantOrRedeemed(uint256 id, address sender);

    struct Lottery {
        address[] participants;
        uint256 ticketPurchaseDeadline;
        uint256 winningBlockNumber;
        uint256 ticketPrice;
        uint256 poolBalance;
        bool claimed;
    }

    Lottery[] public lotteries;
    mapping(uint256 => mapping(address => uint256)) public ticketPurchases;

    function createLottery(uint256 _blockNumber, uint256 _ticketPrice) external {
        if (_blockNumber < block.number) revert InvalidBlockNumber();
        lotteries.push(Lottery(new address[](0), block.timestamp + 24 hours, _blockNumber, _ticketPrice, 0, false));
    }

    function purchaseTicket(uint256 lotteryId) external payable {
        if (lotteries.length <= lotteryId) revert InvalidLotteryId();
        Lottery storage lottery = lotteries[lotteryId];
        if (block.timestamp >= lottery.ticketPurchaseDeadline) revert DeadlineReached();
        if (msg.value < lottery.ticketPrice) revert ValueTooSmall();
        lottery.poolBalance += msg.value;
        ticketPurchases[lotteryId][msg.sender] += msg.value;
        lottery.participants.push(msg.sender);
    }

    function claimWinnings(uint256 lotteryId) external {
        if (lotteries.length <= lotteryId) revert InvalidLotteryId();
        Lottery storage lottery = lotteries[lotteryId];
        if (lottery.claimed) revert LotteryClaimed(lotteryId);
        if (block.timestamp < lottery.ticketPurchaseDeadline + 1 hours) revert LotteryNotOver(lotteryId);
        if (lottery.winningBlockNumber < block.number - 256 || lottery.winningBlockNumber > block.number) {
            revert ExceedBlockHashLimit(block.number);
        }
        uint256 winnerIndex = uint256(blockhash(lottery.winningBlockNumber)) % lottery.participants.length;
        address winner = lottery.participants[winnerIndex];
        (bool success,) = winner.call{value: lottery.poolBalance}("");
        if (!success) revert();
        lottery.claimed = true;
    }

    function redeemTicket(uint256 lotteryId) external {
        if (lotteries.length <= lotteryId) revert InvalidLotteryId();
        Lottery storage lottery = lotteries[lotteryId];
        if (lottery.claimed) revert LotteryClaimed(lotteryId);
        if (block.timestamp < lottery.ticketPurchaseDeadline + 1 hours) revert LotteryNotOver(lotteryId);
        if (ticketPurchases[lotteryId][msg.sender] == 0) revert NotParticipantOrRedeemed(lotteryId, msg.sender);
        if (lottery.winningBlockNumber >= block.number - 256) revert WithinBlockHashLimit(block.number);
        uint256 amount = ticketPurchases[lotteryId][msg.sender];
        ticketPurchases[lotteryId][msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert();
    }
}
