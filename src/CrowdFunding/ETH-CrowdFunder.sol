// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract CrowdFunder {
    error GoalAndDeadlineNotReached(string message);

    struct FundRaiser {
        address creator;
        uint256 goal;
        uint256 balance;
        uint256 deadline;
    }

    FundRaiser[] public fundraisers;
    mapping(uint256 => mapping(address => uint256)) public donations;

    function createFundraiser(uint256 _goal, uint256 _deadline) external {
        fundraisers.push(FundRaiser(msg.sender, _goal, 0, block.timestamp + _deadline));
    }

    function donate(uint256 id) public payable {
        require(fundraisers.length > id, "No Such Campaign!");
        FundRaiser storage fundraiser = fundraisers[id];
        require(fundraiser.deadline > block.timestamp, "This Campaign has ended!");
        fundraiser.balance += msg.value;
        donations[id][msg.sender] += msg.value;
    }

    function withdraw(uint256 id) public {
        require(fundraisers.length > id, "No Such Campaign!");
        FundRaiser storage fundraiser = fundraisers[id];
        if (fundraiser.deadline > block.timestamp) {
            if (fundraiser.balance >= fundraiser.goal) {
                (bool success,) = fundraiser.creator.call{value: fundraiser.balance}("");
                require(success, "Call Failed!");
            } else {
                revert GoalAndDeadlineNotReached(
                    "Wait till goal reached to withdraw for creator or wait till deadline to withdraw donations"
                );
            }
        } else {
            uint256 balance = donations[id][msg.sender];
            donations[id][msg.sender] = 0;
            (bool success,) = msg.sender.call{value: balance}("");
            require(success, "Call Failed!");
        }
    }
}
