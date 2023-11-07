// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vesting} from "../../src/Vesting-Contract/Vesting.sol";
import {Forge} from "../../src/Vesting-Contract/ForgeToken.sol";

contract VestingTest is Test {
    Vesting public vesting;
    Forge public token;
    address receiver;

    event Deposit(address depositor, uint256 amount, uint256 depositTime);
    event Withdraw(address receiver, uint256 dailyWithdrawAmount, uint256 withdrawTime);

    function setUp() public {
        token = new Forge();
        receiver = address(0xdead);
        uint256 vestingPeriod = 5 days;
        vesting = new Vesting(receiver, address(token), vestingPeriod);
    }

    function test_SetUp_State() public {
        assertEq(vesting.receiver(), address(0xdead));
        assertEq(vesting.vestingPeriod(), 5 days);
        assertEq(address(vesting.token()), address(token));
    }

    function testDepositFailsWithNoAllowance() public {
        uint256 depositAmount = 0.5 ether;
        token.mint{value: depositAmount}();
        vm.expectRevert();
        vesting.deposit(depositAmount);
    }

    function testDeposit() public {
        uint256 time = 1234567890;
        vm.warp(time);
        uint256 depositAmount = 0.5 ether;
        uint256 vestingTokenBal = token.balanceOf(address(vesting));
        token.mint{value: depositAmount}();
        token.approve(address(vesting), depositAmount);
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), depositAmount, block.timestamp);
        vesting.deposit(depositAmount);
        assertEq(token.balanceOf(address(vesting)), vestingTokenBal + depositAmount);
        assertEq(vesting.depositedAmount(), depositAmount);
        assertEq(vesting.lastWithdrawTime(), time);
    }

    function testWithdrawRevertsWhenNotReceiver() public {
        vm.expectRevert("Not Receiver!");
        vesting.withraw();
    }

    function testWithdrawRevertsWhenNotWithdrawTime() public {
        uint256 time = 1234567890;
        vm.warp(time);
        uint256 depositAmount = 0.5 ether;
        token.mint{value: depositAmount}();
        token.approve(address(vesting), depositAmount);
        vesting.deposit(depositAmount);
        vm.warp(time + 0.5 days);
        vm.startPrank(receiver);
        vm.expectRevert("Withdraw time not Reached!");
        vesting.withraw();
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint256 time = 1234567890;
        uint256 receiverTokenBal = token.balanceOf(receiver);
        // console.log(token.balanceOf(receiver));
        vm.warp(time);
        uint256 depositAmount = 0.5 ether;
        token.mint{value: depositAmount}();
        token.approve(address(vesting), depositAmount);
        vesting.deposit(depositAmount);
        time += 1 days;
        vm.warp(time);
        vm.startPrank(receiver);
        uint256 withdrawnAmount = depositAmount * 1 days / vesting.vestingPeriod();
        vm.expectEmit(true, true, true, true);
        emit Withdraw(receiver, withdrawnAmount, time);
        vesting.withraw();
        // console.log(token.balanceOf(receiver));
        assertEq(token.balanceOf(receiver), receiverTokenBal + withdrawnAmount);
        assertEq(vesting.lastWithdrawTime(), time);
        // time += 1 days;
        // vm.warp(time);
        // vesting.withraw();
        // console.log(token.balanceOf(receiver));
        // time += 1 days;
        // vm.warp(time);
        // vesting.withraw();
        // console.log(token.balanceOf(receiver));
        // time += 1 days;
        // vm.warp(time);
        // vesting.withraw();
        // console.log(token.balanceOf(receiver));
        // time += 1 days;
        // vm.warp(time);
        // vesting.withraw();
        // console.log(token.balanceOf(receiver));
    }
}
