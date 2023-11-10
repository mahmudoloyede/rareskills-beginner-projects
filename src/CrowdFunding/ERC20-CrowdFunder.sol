// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "./IERC20.sol";

contract CrowdFunder {
    struct FundRaiser {
        address creator;
        address tokenAddress;
        uint256 goal;
        uint256 balance;
        uint256 deadline;
    }

    FundRaiser[] public fundraisers;
    mapping(uint256 => mapping(address => uint256)) public donations;

    error GoalAndDeadlineNotReached(string message);

    function createFundraiser(uint256 _goal, uint256 _deadline, address _token) external {
        fundraisers.push(FundRaiser(msg.sender, _token, _goal, 0, block.timestamp + _deadline));
    }

    function donate(uint256 id, uint256 amount) public {
        require(fundraisers.length > id, "No Such Campaign!");
        FundRaiser storage fundraiser = fundraisers[id];
        require(fundraiser.deadline > block.timestamp, "This Campaign has ended!");
        IERC20 token = IERC20(fundraiser.tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        fundraiser.balance += amount;
        donations[id][msg.sender] += amount;
    }

    function withdraw(uint256 id) public {
        require(fundraisers.length > id, "No Such Campaign!");
        FundRaiser storage fundraiser = fundraisers[id];
        IERC20 token = IERC20(fundraiser.tokenAddress);
        if (fundraiser.deadline > block.timestamp) {
            if (fundraiser.balance >= fundraiser.goal) {
                token.transfer(fundraiser.creator, fundraiser.balance);
            } else {
                revert GoalAndDeadlineNotReached(
                    "Wait till goal reached to withdraw for creator or wait till deadline to withdraw donations"
                );
            }
        } else {
            uint256 balance = donations[id][msg.sender];
            donations[id][msg.sender] = 0;
            token.transfer(msg.sender, balance);
        }
    }
}
