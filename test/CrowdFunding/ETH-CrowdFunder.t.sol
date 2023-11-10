// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFunder} from "../../src/CrowdFunding/ETH-CrowdFunder.sol";

contract CrowdFunderTest is Test {
    CrowdFunder public crowdfunder;

    function setUp() public {
        crowdfunder = new CrowdFunder();
    }

    function testCreateFundRaiser() public {
        uint256 currentTime = 12345;
        vm.warp(currentTime);
        crowdfunder.createFundraiser(10 ether, 15 days);
        (address creator, uint256 goal, uint256 balance, uint256 deadline) = crowdfunder.fundraisers(0);
        // console.log(creator);
        assertEq(creator, address(this));
        // console.log(goal);
        assertEq(goal, 10 ether);
        // console.log(balance);
        assertEq(balance, 0);
        // console.log(deadline);
        assertEq(deadline, 15 days + currentTime);
    }

    function testDonateFailsWhenInvalidId() public {
        crowdfunder.createFundraiser(10 ether, 15 days);
        crowdfunder.createFundraiser(15 ether, 5 days);
        crowdfunder.createFundraiser(20 ether, 20 days);
        vm.expectRevert("No Such Campaign!");
        crowdfunder.donate(3);
    }

    function testDonateFailsWhenDeadlineReached() public {
        vm.warp(12345);
        crowdfunder.createFundraiser(10 ether, 15 days);
        vm.warp(12345 + 15 days);
        vm.expectRevert("This Campaign has ended!");
        crowdfunder.donate(0);
    }

    function testDonate() public {
        vm.prank(address(0xdef));
        crowdfunder.createFundraiser(10 ether, 15 days);
        crowdfunder.donate{value: 5 ether}(0);
        (,, uint256 balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 5 ether);
        assertEq(crowdfunder.donations(0, address(this)), 5 ether);
        crowdfunder.donate{value: 2 ether}(0);
        (,, balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 7 ether);
        assertEq(crowdfunder.donations(0, address(this)), 7 ether);
        hoax(address(0xbad), 2 ether);
        crowdfunder.donate{value: 2 ether}(0);
        (,, balance,) = crowdfunder.fundraisers(0);
        assertEq(balance, 9 ether);
        assertEq(crowdfunder.donations(0, address(0xbad)), 2 ether);
        vm.prank(address(10));
        crowdfunder.createFundraiser(15 ether, 5 days);
        crowdfunder.donate{value: 6 ether}(1);
        (,, uint256 balance1,) = crowdfunder.fundraisers(1);
        assertEq(balance1, 6 ether);
        assertEq(crowdfunder.donations(1, address(this)), 6 ether);
        crowdfunder.donate{value: 4 ether}(1);
        (,, balance1,) = crowdfunder.fundraisers(1);
        assertEq(balance1, 10 ether);
        assertEq(crowdfunder.donations(1, address(this)), 10 ether);
        hoax(address(0xdead), 3 ether);
        crowdfunder.donate{value: 3 ether}(1);
        (,, balance,) = crowdfunder.fundraisers(1);
        assertEq(balance, 13 ether);
        assertEq(crowdfunder.donations(1, address(0xdead)), 3 ether);
        assertEq(address(crowdfunder).balance, 22 ether);
    }

    function testWithdrawFailsWhenInvalidId() public {
        crowdfunder.createFundraiser(10 ether, 15 days);
        crowdfunder.createFundraiser(15 ether, 5 days);
        crowdfunder.createFundraiser(20 ether, 20 days);
        vm.expectRevert("No Such Campaign!");
        crowdfunder.withdraw(3);
    }

    function testWithdrawFailsWhenNotYetDeadlineAndGoalNotReached() public {
        crowdfunder.createFundraiser(10 ether, 15 days);
        hoax(address(0xbad), 7 ether);
        crowdfunder.donate{value: 7 ether}(0);
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
        uint256 thisBalanceBeforeWithdraw = address(this).balance;
        crowdfunder.createFundraiser(5 ether, 2 days);
        hoax(address(0xbad), 3 ether);
        crowdfunder.donate{value: 3 ether}(0);
        hoax(address(0xdeaf), 3 ether);
        crowdfunder.donate{value: 3 ether}(0);
        vm.warp(1 days + block.timestamp);
        crowdfunder.withdraw(0);
        assertEq(address(this).balance, thisBalanceBeforeWithdraw + 6 ether);
        uint256 defBalanceBeforeWithdraw = address(0xdef).balance;
        vm.prank(address(0xdef));
        crowdfunder.createFundraiser(10 ether, 5 days);
        hoax(address(0xbed), 7 ether);
        crowdfunder.donate{value: 7 ether}(1);
        hoax(address(0xdead), 3 ether);
        crowdfunder.donate{value: 3 ether}(1);
        vm.warp(4 days + block.timestamp);
        // vm.prank(address(0xdef));
        crowdfunder.withdraw(1);
        assertEq(address(0xdef).balance, defBalanceBeforeWithdraw + 10 ether);
    }

    function testDonorWithdrawals() public {
        // donors can only withdraw their donations when deadline reaches
        crowdfunder.createFundraiser(10 ether, 7 days);
        crowdfunder.createFundraiser(20 ether, 5 days);
        vm.warp(2 days + 1);
        startHoax(address(0xbad), 15 ether);
        crowdfunder.donate{value: 5 ether}(0);
        crowdfunder.donate{value: 10 ether}(1);
        vm.stopPrank();
        vm.warp(4 days + 1);
        startHoax(address(0xdead), 15 ether);
        crowdfunder.donate{value: 3 ether}(0);
        crowdfunder.donate{value: 7 ether}(1);
        vm.stopPrank();
        vm.warp(10 days);
        uint256 badBalanceBefore1stWithraw = address(0xbad).balance;
        vm.prank(address(0xbad));
        crowdfunder.withdraw(0);
        assertEq(address(0xbad).balance, badBalanceBefore1stWithraw + 5 ether);
        uint256 badBalanceBefore2ndWithraw = address(0xbad).balance;
        vm.prank(address(0xbad));
        crowdfunder.withdraw(1);
        assertEq(address(0xbad).balance, badBalanceBefore2ndWithraw + 10 ether);
        uint256 deadBalanceBefore1stWithraw = address(0xdead).balance;
        vm.prank(address(0xdead));
        crowdfunder.withdraw(0);
        assertEq(address(0xdead).balance, deadBalanceBefore1stWithraw + 3 ether);
        uint256 deadBalanceBefore2ndWithraw = address(0xdead).balance;
        vm.prank(address(0xdead));
        crowdfunder.withdraw(1);
        assertEq(address(0xdead).balance, deadBalanceBefore2ndWithraw + 7 ether);
    }

    receive() external payable {}
}
