// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "./IERC20.sol";

contract Staker {
  struct Stake {
    uint amount;
    uint stakeDate;
    bool collectedReward;
  }
  uint public immutable BEGIN_DATE;
  uint public immutable EXPIRATION;
  uint public totalStaked;
  address public immutable CLOUD_ADDRESS;
  mapping(address => Stake) public stakes;

  constructor(address _cloudAddress, uint _beginDate, uint _expiration){
    BEGIN_DATE = block.timestamp + _beginDate;
    EXPIRATION = block.timestamp + _expiration;
    CLOUD_ADDRESS = _cloudAddress;
    IERC20 cloud = IERC20(CLOUD_ADDRESS);
    cloud.mint(1_000_000 ether);
  }

  function stake(uint amount) external {
    require(block.timestamp >= BEGIN_DATE && block.timestamp < EXPIRATION, "Not Yet Start Time or Deadline Reached");
    IERC20 cloud = IERC20(CLOUD_ADDRESS);
    cloud.transferFrom(msg.sender, address(this), amount);
    totalStaked += amount;
    stakes[msg.sender].amount += amount;
    stakes[msg.sender].stakeDate = block.timestamp;
  }

  function collectStakeAndReward() external {
    require(block.timestamp >= EXPIRATION, "Wait Till Deadline to Withdraw Stake and Reward");
    require(stakes[msg.sender].amount != 0, "You didn't stake");
    require(!stakes[msg.sender].collectedReward, "Reward Already Collected");
    IERC20 cloud = IERC20(CLOUD_ADDRESS);
    if (block.timestamp >= stakes[msg.sender].stakeDate + 7 days){
      uint reward = stakes[msg.sender].amount * 1_000_000 ether / totalStaked;
      cloud.transfer(msg.sender, reward + stakes[msg.sender].amount);
    }else{
      cloud.transfer(msg.sender, stakes[msg.sender].amount);
    }
    stakes[msg.sender].collectedReward = true;
  }
}
