pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct TokenFund {
    address tokenAddress;
    uint256 funds;
}

contract EwwLocker {
    mapping(address => mapping(string => uint256)) public funds;
    mapping(address => mapping(address => mapping(string => bool))) public allowances;
    mapping(address => mapping(string => uint256)) public lastRetrievals;
    mapping(address => mapping(string => uint256)) public dailyFundsRetrieved;
    mapping(address => mapping(string => uint256)) private dailyLimit;
    mapping(address => mapping(string => address)) private fundOwners;
    mapping(string => address[]) private worldTokenAddresses;
    uint256 private blockStart;

    event AddedFunds(address _from, address _destAddr, uint256 _amount);
    event RetrievedFunds(address _toAddress, uint256 _amount);

    constructor() {
        blockStart = block.number;
    }

    function addFunds(address tokenAddress, string memory worldId, uint256 amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Insufficient balance or allowance");
        emit AddedFunds(msg.sender, address(this), amount);

        funds[tokenAddress][worldId] += amount;
        worldTokenAddresses[worldId].push(tokenAddress);
        fundOwners[tokenAddress][worldId] = msg.sender;
    }

    function retrieveFunds(address tokenAddress, address toAddress, string memory worldId, uint256 amount) public {
        require(allowances[tokenAddress][msg.sender][worldId], "Address not authorized to retrieve funds");
        require(amount <= funds[tokenAddress][worldId], "Insufficient funds");
        uint256 limit = dailyLimit[tokenAddress][worldId];
        uint256 todayFundsRetrieved = dailyFundsRetrieved[tokenAddress][worldId];

        if (block.timestamp >= lastRetrievals[tokenAddress][worldId] + 24 hours) {
            todayFundsRetrieved = 0;
        }

        require(todayFundsRetrieved + amount <= limit, "Amount exceeds daily limit");

        funds[tokenAddress][worldId] -= amount;
        IERC20 token = IERC20(tokenAddress);
        token.transfer(toAddress, amount);
        lastRetrievals[tokenAddress][worldId] = block.timestamp;
        dailyFundsRetrieved[tokenAddress][worldId] += amount;

        emit RetrievedFunds(toAddress, amount);
    }

    function withdrawFunds(address tokenAddress, string memory worldId) public {
        require(fundOwners[tokenAddress][worldId] == msg.sender, "The msg.sender is not the owner of these funds");
        uint256 amount = funds[tokenAddress][worldId];

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
        funds[tokenAddress][worldId] = 0;
    }

    function allowAddress(address tokenAddress, address allowedAddress, string memory worldId) public {
        require(fundOwners[tokenAddress][worldId] == msg.sender, "Only the fund owner can set allowances");
        allowances[tokenAddress][allowedAddress][worldId] = true;
    }

    function disallowAddress(address tokenAddress, address disallowedAddress, string memory worldId) public {
        require(fundOwners[tokenAddress][worldId] == msg.sender, "Only the fund owner can set allowances");
        allowances[tokenAddress][disallowedAddress][worldId] = false;
    }

    function getAllFunds(string memory worldId) public view returns (TokenFund[] memory) {
        address[] memory tokenAddresses = worldTokenAddresses[worldId];
        TokenFund[] memory result = new TokenFund[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            result[i].tokenAddress = tokenAddresses[i];
            result[i].funds = funds[tokenAddresses[i]][worldId];
        }
        return result;
    }

    function setDailyLimit(address tokenAddress, string memory worldId, uint256 limit) public {
        require(fundOwners[tokenAddress][worldId] == msg.sender, "The msg.sender is not the owner of these funds");
        dailyLimit[tokenAddress][worldId] = limit;
    }
}
