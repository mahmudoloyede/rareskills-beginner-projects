// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staker} from "../../src/Stake-Together/Staker.sol";
import {CloudToken} from "./CloudToken.sol";

contract StakerTest is Test {
  Staker public staker;
  CloudToken public cloudToken;

  function setUp() public {
    cloudToken = new CloudToken();
    staker = new Staker(address(cloudToken), 2 days, 16 days);
  }

  function testSetUpState() public {
    assertEq(staker.CLOUD_ADDRESS(), address(cloudToken));
    assertEq(staker.BEGIN_DATE(), block.timestamp + 2 days);
    assertEq(staker.EXPIRATION(), block.timestamp + 16 days);
    assertEq(cloudToken.balanceOf(address(staker)), 1_000_000 ether);
  }

  function testStakeFailsIfNotBeginTime() public {
    vm.warp(block.timestamp + 1.5 days);
    vm.expectRevert("Not Yet Start Time or Deadline Reached");
    staker.stake(1 ether);
  }

  function testStakeFailsAtDeadline() public {
    vm.warp(block.timestamp + 16 days);
    vm.expectRevert("Not Yet Start Time or Deadline Reached");
    staker.stake(1 ether);
  }

  function testStake() public {
    cloudToken.mint(5 ether);
    cloudToken.approve(address(staker), 5 ether);
    uint stakerCloudBal = cloudToken.balanceOf(address(staker));
    uint thisCloudBal = cloudToken.balanceOf(address(this));
    uint totalStaked = staker.totalStaked();
    (uint amount, uint stakeDate, bool collectedReward) = staker.stakes(address(this));
    assertEq(amount, 0);
    assertEq(stakeDate, 0);
    assertFalse(collectedReward);
    vm.warp(block.timestamp + 5 days);
    staker.stake(5 ether);
    assertEq(cloudToken.balanceOf(address(staker)), stakerCloudBal + 5 ether);
    assertEq(cloudToken.balanceOf(address(this)), thisCloudBal - 5 ether);
    assertEq(staker.totalStaked(), totalStaked + 5 ether);
    (amount, stakeDate, collectedReward) = staker.stakes(address(this));
    assertEq(amount, 5 ether);
    assertEq(stakeDate, block.timestamp);
    assertFalse(collectedReward);
  }

  function testCollectStakeAndRewardFailsWhenNotDeadline() public {
    cloudToken.mint(5 ether);
    cloudToken.approve(address(staker), 5 ether);
    vm.warp(block.timestamp + 5 days);
    staker.stake(5 ether);
    vm.warp(10 days);
    vm.expectRevert("Wait Till Deadline to Withdraw Stake and Reward");
    staker.collectStakeAndReward();
  }

  function testCollectStakeAndRewardFailsWhenNoStake() public {
    vm.warp(17 days);
    vm.expectRevert("You didn't stake");
    staker.collectStakeAndReward();
  }

  function testCollectStakeAndRewardFailsWhenAlreadyCollected() public {
    cloudToken.mint(5 ether);
    cloudToken.approve(address(staker), 5 ether);
    vm.warp(block.timestamp + 5 days);
    staker.stake(5 ether);
    vm.warp(17 days);
    staker.collectStakeAndReward();
    vm.warp(18 days);
    vm.expectRevert("Reward Already Collected");
    staker.collectStakeAndReward();
  }

  function testCollectStakeAndRewardWhenStakedForAtleast7Days() public {
    cloudToken.mint(5000 ether);
    cloudToken.approve(address(staker), 5000 ether);
    vm.warp(block.timestamp + 2 days);
    staker.stake(5000 ether);
    for (uint i = 1; i < 5; ++i){
      vm.startPrank(address(uint160(i)));
      cloudToken.mint(5000 ether);
      cloudToken.approve(address(staker), 5000 ether);
      vm.warp(block.timestamp + i+2 days);
      staker.stake(5000 ether);
      vm.stopPrank();
    }
    vm.warp(17 days);
    uint stakerCloudBal = cloudToken.balanceOf(address(staker));
    uint thisCloudBal = cloudToken.balanceOf(address(this));
    staker.collectStakeAndReward();
    (uint stakedAmount,,bool collected) = staker.stakes(address(this));
    uint reward = stakedAmount * 1_000_000 ether / staker.totalStaked();
    assertEq(cloudToken.balanceOf(address(this)), thisCloudBal + (reward + stakedAmount));
    assertEq(cloudToken.balanceOf(address(staker)), stakerCloudBal - (reward + stakedAmount));
    assertTrue(collected);
  }
  
  function testCollectStakeAndRewardWhenStakedForLessThan7Days() public {
    cloudToken.mint(5000 ether);
    cloudToken.approve(address(staker), 5000 ether);
    vm.warp(block.timestamp + 10 days);
    staker.stake(5000 ether);
    vm.warp(17 days);
    uint stakerCloudBal = cloudToken.balanceOf(address(staker));
    uint thisCloudBal = cloudToken.balanceOf(address(this));
    staker.collectStakeAndReward();
    (uint stakedAmount,,bool collected) = staker.stakes(address(this));
    assertEq(cloudToken.balanceOf(address(this)), thisCloudBal + stakedAmount);
    assertEq(cloudToken.balanceOf(address(staker)), stakerCloudBal - stakedAmount);
    assertTrue(collected);
  }
}
