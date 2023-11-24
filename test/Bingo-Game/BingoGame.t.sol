// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {BingoGame} from "../../src/Bingo-Game/BingoGame.sol";

contract BingoGameTest is Test {
    BingoGame public bingo;

    event CardCreated(address indexed player, uint8[25] card);
    event NumberCalled(uint8 number);

    function setUp() public {
        bingo = new BingoGame();
    }

    function testBuyTicketFailsWhenValueTooSmall() public {
        vm.expectRevert(BingoGame.ValueTooSmall.selector);
        bingo.buyTicket{value: 0.09 ether}();
    }

    function testBuyTicket() public {
        uint8[25] memory sampleCard;
        vm.expectEmit(true, true, true, false);
        emit CardCreated(address(this), sampleCard);
        bingo.buyTicket{value: 0.1 ether}();
        for (uint256 i; i < 25; i++) {
            uint256 num = bingo.playerCards(address(this), i);
            assertApproxEqAbs(num, 25, 24);
            sampleCard[i] = uint8(num);
        }
    }

    function testCallNumberFailsIfNotOwner() public {
        vm.startPrank(address(1));
        vm.expectRevert(BingoGame.NotOwner.selector);
        bingo.callNumber();
        vm.stopPrank();
    }

    function testCallNumberFailsIfAllNumberCalled() public {
        for (uint256 i; i < 25; i++) {
            bingo.callNumber();
        }
        vm.expectRevert(BingoGame.AllNumbersCalled.selector);
        bingo.callNumber();
    }

    function testCallNumber() public {
        bingo.buyTicket{value: 0.1 ether}();
        for (uint256 i; i < 14; i++) {
            bingo.callNumber();
        }
        vm.expectEmit(true, true, true, true);
        emit NumberCalled(15);
        bingo.callNumber();
        assertEq(bingo.calledNumbers(14), 15);
        assertEq(bingo.calledCount(), 15);
        assertTrue(bingo.hasBingo(address(this)));
    }
}
