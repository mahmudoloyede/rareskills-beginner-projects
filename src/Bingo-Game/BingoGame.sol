// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract BingoGame {
    error ValueTooSmall();
    error NotOwner();
    error AllNumbersCalled();

    uint8 public constant gridSize = 5; // 5x5 grid
    uint256 public constant maxNumbers = gridSize * gridSize;

    address public owner;
    uint256 public ticketPrice = 0.1 ether;

    mapping(address => uint8[maxNumbers]) public playerCards;
    mapping(address => bool) public hasBingo;
    uint8[maxNumbers] public calledNumbers;
    address[] public players;
    uint256 public calledCount;

    event CardCreated(address indexed player, uint8[maxNumbers] card);
    event NumberCalled(uint8 number);
    event Bingo(address indexed player);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function buyTicket() external payable {
        if (msg.value < ticketPrice) revert ValueTooSmall();

        uint8[maxNumbers] memory card;
        for (uint8 i = 0; i < maxNumbers; i++) {
            card[i] = i + 1;
        }

        // Shuffle card - optional but could increase fairness
        _shuffleArray(card);

        playerCards[msg.sender] = card;
        players.push(msg.sender);

        emit CardCreated(msg.sender, card);
    }

    function _shuffleArray(uint8[maxNumbers] memory arr) internal view {
        uint256 n = arr.length;
        while (n > 1) {
            uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % n;
            n--;
            uint8 temp = arr[n];
            arr[n] = arr[randIndex];
            arr[randIndex] = temp;
        }
    }

    function callNumber() external onlyOwner {
        if (calledCount >= maxNumbers) revert AllNumbersCalled();
        uint8 number = uint8(calledCount) + 1;
        emit NumberCalled(number);
        calledNumbers[calledCount] = number;
        calledCount++;

        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            if (_hasBingo(player)) {
                hasBingo[player] = true;
                emit Bingo(player);
            }
        }
    }

    function _hasBingo(address player) public view returns (bool) {
        uint8[maxNumbers] memory card = playerCards[player];

        // Check rows
        for (uint8 i = 0; i < gridSize; i++) {
            bool isRowComplete = true;
            uint8 start = i * gridSize;
            for (uint8 j = start; j < start + gridSize; j++) {
                if (!isNumberCalled(card[j])) {
                    isRowComplete = false;
                    break;
                }
            }
            if (isRowComplete) {
                return true;
            }
        }

        // Check columns
        for (uint8 i = 0; i < gridSize; i++) {
            bool isColComplete = true;
            for (uint8 j = i; j < maxNumbers; j += gridSize) {
                if (!isNumberCalled(card[j])) {
                    isColComplete = false;
                    break;
                }
            }
            if (isColComplete) {
                return true;
            }
        }

        // Check diagonals
        bool isMainDiagonalComplete = true;
        bool isSecondaryDiagonalComplete = true;
        for (uint8 i = 0; i < gridSize; i++) {
            if (!isNumberCalled(card[i * gridSize + i])) {
                isMainDiagonalComplete = false;
            }
            if (!isNumberCalled(card[(i + 1) * (gridSize - 1)])) {
                isSecondaryDiagonalComplete = false;
            }
        }
        if (isMainDiagonalComplete || isSecondaryDiagonalComplete) {
            return true;
        }

        return false;
    }

    function isNumberCalled(uint8 number) internal view returns (bool) {
        for (uint256 i = 0; i < calledCount; i++) {
            if (calledNumbers[i] == number) {
                return true;
            }
        }
        return false;
    }
}
