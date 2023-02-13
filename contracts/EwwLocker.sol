pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct TokenFund {
    address tokenAddress;
    uint256 funds;
}

contract EwwLocker {
    mapping(address => mapping(string => uint256)) public funds;
    mapping(address => mapping(address => bool)) public allowances;
    mapping(address => mapping(string => uint256)) private dailyLimit;
    mapping(address => mapping(string => uint256)) private lastRetrievals;
    mapping(address => mapping(string => address)) private fundOwners;
    mapping(string => address[]) private worldTokenAddresses;
    uint256 private blockStart;

    event AddedFunds(address _from, address _destAddr, uint256 _amount);

    constructor() {
        blockStart = block.number;
    }

    function addFunds(
        address tokenAddress,
        string memory worldId,
        uint256 amount
    ) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.approve(msg.sender, amount);
        require(token.transferFrom(msg.sender, address(this), amount), "Insufficient balance or allowance");
        emit AddedFunds(msg.sender, address(this), amount);

        funds[tokenAddress][worldId] += amount;
        worldTokenAddresses[worldId].push(tokenAddress);
        fundOwners[tokenAddress][worldId] = msg.sender;
    }

    function retrieveFunds(
        address tokenAddress,
        string memory worldId,
        uint256 amount
    ) public {
        require(allowances[tokenAddress][msg.sender], "Address not authorized to retrieve funds");
        require(amount <= funds[tokenAddress][worldId], "Insufficient funds");
        require(
            block.timestamp >= lastRetrievals[tokenAddress][worldId] + 24 hours,
            "You have already reached the daily limit."
        );

        uint256 limit = dailyLimit[tokenAddress][worldId];
        require(amount <= limit, "Amount exceeds daily limit");

        funds[tokenAddress][worldId] -= amount;
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
        lastRetrievals[tokenAddress][worldId] = block.timestamp;
    }

    function withdrawFunds(address tokenAddress, string memory worldId) public payable {
        require(fundOwners[tokenAddress][worldId] == msg.sender, "The msg.sender is not the owner of these funds");
        uint256 amount = funds[tokenAddress][worldId];

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
        funds[tokenAddress][worldId] = 0;
    }

    function getCurrentLimit(address tokenAddress, string memory worldId) public view returns (uint256) {
        return dailyLimit[tokenAddress][worldId];
    }

    function getCurrentLimitA(address tokenAddress, string memory worldId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 limit = dailyLimit[tokenAddress][worldId];
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastRetrieval = currentTime - lastRetrievals[tokenAddress][worldId];
        uint256 maxAmount = (limit * timeSinceLastRetrieval) / 86400;

        return (limit, timeSinceLastRetrieval, maxAmount);
    }

    function allowAddress(address tokenAddress, address allowedAddress) public payable {
        allowances[tokenAddress][allowedAddress] = true;
    }

    function disallowAddress(address tokenAddress, address disallowedAddress) public payable {
        allowances[tokenAddress][disallowedAddress] = false;
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

    function setDailyLimit(
        address tokenAddress,
        string memory worldId,
        uint256 limit
    ) public payable {
        dailyLimit[tokenAddress][worldId] = limit;
    }
}
