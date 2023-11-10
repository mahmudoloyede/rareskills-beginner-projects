// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFunder} from "../../src/CrowdFunding/ERC20-CrowdFunder.sol";
import {Sample} from "./SampleToken.sol";

contract CrowdFunderTest is Test {
    Sample public token1;
    Sample public token2;
    Sample public token3;
    CrowdFunder public crowdfunder;

    function setUp() public {
        token1 = new Sample();
        token2 = new Sample();
        token3 = new Sample();
        crowdfunder = new CrowdFunder();
    }

    function testCreateFundRaiser() public {
        uint256 currentTime = 45678;
        vm.warp(currentTime);
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        (address creator, address tokenAddress, uint256 goal, uint256 balance, uint256 deadline) =
            crowdfunder.fundraisers(0);
        assertEq(creator, address(this));
        assertEq(tokenAddress, address(token1));
        assertEq(goal, 10 ether);
        assertEq(balance, 0);
        assertEq(deadline, currentTime + 15 days);
    }

    function testDonateFailsWhenInvalidId() public {
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        crowdfunder.createFundraiser(15 ether, 5 days, address(token2));
        crowdfunder.createFundraiser(20 ether, 20 days, address(token3));
        vm.expectRevert("No Such Campaign!");
        crowdfunder.donate(3, 10 ether);
    }

    function testDonateFailsWhenDeadlineReached() public {
        vm.warp(12345);
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        vm.warp(12345 + 15 days);
        vm.expectRevert("This Campaign has ended!");
        crowdfunder.donate(0, 7 ether);
    }

    function testDonate() public {
        vm.prank(address(0xdef));
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        token1.mint(7 ether);
        token1.approve(address(crowdfunder), 7 ether);
        crowdfunder.donate(0, 5 ether);
        (,,, uint256 balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 5 ether);
        assertEq(crowdfunder.donations(0, address(this)), 5 ether);
        crowdfunder.donate(0, 2 ether);
        (,,, balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 7 ether);
        assertEq(crowdfunder.donations(0, address(this)), 7 ether);
        vm.startPrank(address(0xbad));
        token1.mint(2 ether);
        token1.approve(address(crowdfunder), 2 ether);
        crowdfunder.donate(0, 2 ether);
        vm.stopPrank();
        (,,, balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 9 ether);
        assertEq(crowdfunder.donations(0, address(0xbad)), 2 ether);
        assertEq(token1.balanceOf(address(crowdfunder)), 9 ether);
        vm.prank(address(10));
        crowdfunder.createFundraiser(15 ether, 5 days, address(token2));
        token2.mint(10 ether);
        token2.approve(address(crowdfunder), 10 ether);
        crowdfunder.donate(1, 6 ether);
        (,,, uint256 balance1,) = crowdfunder.fundraisers(1);
        assertEq(balance1, 6 ether);
        assertEq(crowdfunder.donations(1, address(this)), 6 ether);
        crowdfunder.donate(1, 4 ether);
        (,,, balance1,) = crowdfunder.fundraisers(1);
        assertEq(balance1, 10 ether);
        assertEq(crowdfunder.donations(1, address(this)), 10 ether);
        vm.startPrank(address(0xdead));
        token2.mint(3 ether);
        token2.approve(address(crowdfunder), 3 ether);
        crowdfunder.donate(1, 3 ether);
        vm.stopPrank();
        (,,, balance,) = crowdfunder.fundraisers(1);
        assertEq(balance, 13 ether);
        assertEq(crowdfunder.donations(1, address(0xdead)), 3 ether);
        assertEq(token2.balanceOf(address(crowdfunder)), 13 ether);
    }

    function testWithdrawFailsWhenInvalidId() public {
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        crowdfunder.createFundraiser(15 ether, 5 days, address(token2));
        crowdfunder.createFundraiser(20 ether, 20 days, address(token3));
        vm.expectRevert("No Such Campaign!");
        crowdfunder.withdraw(3);
    }

    function testWithdrawFailsWhenNotYetDeadlineAndGoalNotReached() public {
        crowdfunder.createFundraiser(10 ether, 15 days, address(token1));
        vm.startPrank(address(0xbad));
        token1.mint(7 ether);
        token1.approve(address(crowdfunder), 7 ether);
        crowdfunder.donate(0, 7 ether);
        vm.stopPrank();
        vm.warp(10 days + block.timestamp);
        vm.expectRevert(
            abi.encodeWithSelector(
                CrowdFunder.GoalAndDeadlineNotReached.selector,
                "Wait till goal reached to withdraw for creator or wait till deadline to withdraw donations"
            )
        );
        crowdfunder.withdraw(0);
    }

    function testWithrawToCreator() public {
        // Can only be withdrawn to creator if deadline not reached and goal reached
        uint256 thisToken1BalanceBeforeWithdraw = token1.balanceOf(address(this));
        crowdfunder.createFundraiser(5 ether, 2 days, address(token1));
        vm.startPrank(address(0xbad));
        token1.mint(3 ether);
        token1.approve(address(crowdfunder), 3 ether);
        crowdfunder.donate(0, 3 ether);
        vm.stopPrank();
        vm.startPrank(address(0xdeaf));
        token1.mint(3 ether);
        token1.approve(address(crowdfunder), 3 ether);
        crowdfunder.donate(0, 3 ether);
        vm.stopPrank();
        vm.warp(1 days + block.timestamp);
        crowdfunder.withdraw(0);
        assertEq(token1.balanceOf(address(this)), thisToken1BalanceBeforeWithdraw + 6 ether);
        uint256 defToken2BalanceBeforeWithdraw = token2.balanceOf(address(0xdef));
        vm.prank(address(0xdef));
        crowdfunder.createFundraiser(10 ether, 5 days, address(token2));
        vm.startPrank(address(0xbed));
        token2.mint(7 ether);
        token2.approve(address(crowdfunder), 7 ether);
        crowdfunder.donate(1, 7 ether);
        vm.stopPrank();
        vm.startPrank(address(0xdead));
        token2.mint(3 ether);
        token2.approve(address(crowdfunder), 3 ether);
        crowdfunder.donate(1, 3 ether);
        vm.stopPrank();
        vm.warp(4 days + block.timestamp);
        // vm.prank(address(0xdef));
        crowdfunder.withdraw(1);
        assertEq(token2.balanceOf(address(0xdef)), defToken2BalanceBeforeWithdraw + 10 ether);
    }

    function testDonorWithdrawals() public {
        // donors can only withdraw their donations when deadline reaches
        crowdfunder.createFundraiser(10 ether, 7 days, address(token1));
        crowdfunder.createFundraiser(20 ether, 5 days, address(token2));
        vm.warp(2 days + 1);
        vm.startPrank(address(0xbad));
        token1.mint(5 ether);
        token2.mint(10 ether);
        token1.approve(address(crowdfunder), 5 ether);
        token2.approve(address(crowdfunder), 10 ether);
        crowdfunder.donate(0, 5 ether);
        crowdfunder.donate(1, 10 ether);
        vm.stopPrank();
        vm.warp(4 days + 1);
        vm.startPrank(address(0xdead));
        token1.mint(3 ether);
        token2.mint(7 ether);
        token1.approve(address(crowdfunder), 3 ether);
        token2.approve(address(crowdfunder), 7 ether);
        crowdfunder.donate(0, 3 ether);
        crowdfunder.donate(1, 7 ether);
        vm.stopPrank();
        vm.warp(10 days);
        uint256 badToken1BalanceBeforeWithraw = token1.balanceOf(address(0xbad));
        uint256 badToken2BalanceBeforeWithraw = token2.balanceOf(address(0xbad));
        vm.prank(address(0xbad));
        crowdfunder.withdraw(0);
        assertEq(token1.balanceOf(address(0xbad)), badToken1BalanceBeforeWithraw + 5 ether);
        vm.prank(address(0xbad));
        crowdfunder.withdraw(1);
        assertEq(token2.balanceOf(address(0xbad)), badToken2BalanceBeforeWithraw + 10 ether);
        uint256 deadToken1BalanceBeforeWithraw = token1.balanceOf(address(0xdead));
        uint256 deadToken2BalanceBeforeWithraw = token2.balanceOf(address(0xdead));
        vm.prank(address(0xdead));
        crowdfunder.withdraw(0);
        assertEq(token1.balanceOf(address(0xdead)), deadToken1BalanceBeforeWithraw + 3 ether);
        vm.prank(address(0xdead));
        crowdfunder.withdraw(1);
        assertEq(token2.balanceOf(address(0xdead)), deadToken2BalanceBeforeWithraw + 7 ether);
    }
}
