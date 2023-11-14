// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "./IERC20.sol";

contract Vesting {
    address public immutable receiver;
    uint256 public immutable vestingPeriod;
    address public tokenAddress;
    uint256 public lastWithdrawTime;
    uint256 public depositedAmount;

    event Deposit(address depositor, uint256 amount, uint256 depositTime);
    event Withdraw(address receiver, uint256 dailyWithdrawAmount, uint256 withdrawTime);

    constructor(address _receiver, address _tokenAddress, uint256 _vestingPeriod) {
        receiver = _receiver;
        vestingPeriod = _vestingPeriod;
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        depositedAmount = amount;
        lastWithdrawTime = block.timestamp;
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function withraw() external {
        require(msg.sender == receiver, "Not Receiver!");
        require(block.timestamp >= lastWithdrawTime + 1 days, "Withdraw time not Reached!");
        IERC20 token = IERC20(tokenAddress);
        uint256 dailyAmount = depositedAmount * 1 days / vestingPeriod;
        token.transfer(receiver, dailyAmount);
        lastWithdrawTime = block.timestamp;
        emit Withdraw(receiver, dailyAmount, block.timestamp);
    }
}
