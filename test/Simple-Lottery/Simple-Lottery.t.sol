// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleLottery} from "../../src/Simple-Lottery/Simple-Lottery.sol";

contract SimpleLotteryTest is Test {
    SimpleLottery public lottery;

    function setUp() public {
        lottery = new SimpleLottery();
    }

    function testCreateLotteryFailsIfPastBlockNumber() public {
        vm.roll(12345);
        vm.expectRevert(SimpleLottery.InvalidBlockNumber.selector);
        lottery.createLottery(100, 0.1 ether);
    }

    function testCreateLottery() public {
        lottery.createLottery(100, 0.1 ether);
        (uint256 purchaseDeadline, uint256 winningBlock, uint256 ticketPrice, uint256 poolBalance, bool claimed) =
            lottery.lotteries(0);
        assertEq(purchaseDeadline, block.timestamp + 24 hours);
        assertEq(winningBlock, 100);
        assertEq(ticketPrice, 0.1 ether);
        assertEq(poolBalance, 0);
        assertFalse(claimed);
    }

    function testPurchaseTicketFailsWithInvalidId() public {
        lottery.createLottery(100, 0.1 ether);
        lottery.createLottery(170, 0.3 ether);
        lottery.createLottery(120, 0.5 ether);
        vm.expectRevert(SimpleLottery.InvalidLotteryId.selector);
        lottery.purchaseTicket(3);
    }

    function testPurchaseTicketFailsAtDeadline() public {
        lottery.createLottery(100, 0.1 ether);
        vm.warp(block.timestamp + 25 hours);
        vm.expectRevert(SimpleLottery.DeadlineReached.selector);
        lottery.purchaseTicket(0);
    }

    function testPurchaseTicketFailsWithSmallValue() public {
        lottery.createLottery(100, 0.1 ether);
        vm.expectRevert(SimpleLottery.ValueTooSmall.selector);
        lottery.purchaseTicket{value: 0.09 ether}(0);
    }

    function testPurchaseTicket() public {
        lottery.createLottery(100, 0.1 ether);
        (,,, uint256 oldpoolBalance,) = lottery.lotteries(0);
        lottery.purchaseTicket{value: 0.1 ether}(0);
        (,,, uint256 newpoolBalance,) = lottery.lotteries(0);
        assertEq(newpoolBalance, oldpoolBalance + 0.1 ether);
        assertEq(lottery.ticketPurchases(0, address(this)), 0.1 ether);
    }

    function testClaimWinningsFailsWithInvalidId() public {
        lottery.createLottery(100, 0.1 ether);
        lottery.createLottery(170, 0.3 ether);
        lottery.createLottery(120, 0.5 ether);
        vm.expectRevert(SimpleLottery.InvalidLotteryId.selector);
        lottery.claimWinnings(3);
    }

    function testClaimWinningsFailsIfAlreadyClaimed() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(2 days);
        vm.roll(10200);
        lottery.claimWinnings(0);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.LotteryClaimed.selector, 0));
        lottery.claimWinnings(0);
    }

    function testClaimWinningsFailsIfLotteryNotOver() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(1 days);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.LotteryNotOver.selector, 0));
        lottery.claimWinnings(0);
    }

    function testClaimWinningsFailsIfWinningBlockNumberExceedLimit() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(2 days);
        vm.roll(10257);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.ExceedBlockHashLimit.selector, 10257));
        lottery.claimWinnings(0);
    }

    function testClaimWinningsFailsIfWInningBlockNotReached() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(2 days);
        vm.roll(9700);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.ExceedBlockHashLimit.selector, 9700));
        lottery.claimWinnings(0);
    }

    function testClaimWinnings() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(2), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(3), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(4), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        address[4] memory participants = [address(1), address(2), address(3), address(4)];
        vm.warp(2 days);
        vm.roll(10100);
        lottery.claimWinnings(0);
        uint256 winnerIndex = uint256(blockhash(10100)) % 4;
        (,,, uint256 poolBalance, bool claimed) = lottery.lotteries(0);
        // all blockhash are 0x0000000000000000000000000000000000000000000000000000000000000000. So the winner will always be the first address  to purchase the ticket
        address winner = participants[winnerIndex];
        assertEq(winner.balance, poolBalance);
        assertTrue(claimed);
    }

    function testRedeemTicketFailsWithInvalidLotteryId() public {
        lottery.createLottery(100, 0.1 ether);
        lottery.createLottery(170, 0.3 ether);
        lottery.createLottery(120, 0.5 ether);
        vm.expectRevert(SimpleLottery.InvalidLotteryId.selector);
        lottery.redeemTicket(3);
    }

    function testRedeemTicketFailsIfWinningsClaimed() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(2 days);
        vm.roll(10200);
        lottery.claimWinnings(0);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.LotteryClaimed.selector, 0));
        lottery.redeemTicket(0);
    }

    function testRedeemTicketFailsIfLotteryNotOver() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(1 days);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.LotteryNotOver.selector, 0));
        lottery.redeemTicket(0);
    }

    function testRedeemTicketFailsIfNotParticipantOrAlreadyRedeemed() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(2), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(3), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(4), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.roll(10500);
        vm.warp(2 days);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.NotParticipantOrRedeemed.selector, 0, address(this)));
        lottery.redeemTicket(0);
        vm.startPrank(address(1));
        lottery.redeemTicket(0);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.NotParticipantOrRedeemed.selector, 0, address(1)));
        lottery.redeemTicket(0);
        vm.stopPrank();
    }

    function testRedeemTicketFailsIfWinningBlockInTheFutureOrWithinBlockHashLimit() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.warp(2 days);
        vm.roll(10200);
        vm.startPrank(address(1));
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.WithinBlockHashLimit.selector, 10200));
        lottery.redeemTicket(0);
        vm.roll(9505);
        vm.expectRevert(abi.encodeWithSelector(SimpleLottery.WithinBlockHashLimit.selector, 9505));
        lottery.redeemTicket(0);
        vm.stopPrank();
    }

    function testRedeemTicket() public {
        vm.roll(9500);
        lottery.createLottery(10000, 0.5 ether);
        hoax(address(1), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(2), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(3), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        hoax(address(4), 0.5 ether);
        lottery.purchaseTicket{value: 0.5 ether}(0);
        vm.roll(10500);
        vm.warp(2 days);
        vm.startPrank(address(1));
        lottery.redeemTicket(0);
        assertEq(address(1).balance, 0.5 ether);
        assertEq(lottery.ticketPurchases(0, address(1)), 0);
        vm.stopPrank();
        vm.startPrank(address(2));
        lottery.redeemTicket(0);
        assertEq(address(2).balance, 0.5 ether);
        assertEq(lottery.ticketPurchases(0, address(2)), 0);
        vm.stopPrank();
        vm.startPrank(address(3));
        lottery.redeemTicket(0);
        assertEq(address(3).balance, 0.5 ether);
        assertEq(lottery.ticketPurchases(0, address(3)), 0);
        vm.stopPrank();
        vm.startPrank(address(4));
        lottery.redeemTicket(0);
        assertEq(address(4).balance, 0.5 ether);
        assertEq(lottery.ticketPurchases(0, address(4)), 0);
        vm.stopPrank();
    }

    receive() external payable {}
}
