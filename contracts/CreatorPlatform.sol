// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/access/AccessControl.sol?raw=true";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/utils/Pausable.sol?raw=true";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/utils/ReentrancyGuard.sol?raw=true";

contract CreatorPlatform is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public platformFee = 5;
    uint256 public collectedFees;

    struct Creator {
        string name;
        bool isRegistered;
        uint256 totalTipsReceived;
    }

    mapping(address => Creator) public creators;

    event CreatorRegistered(address indexed creator, string name);
    event TipSent(address indexed from, address indexed to, uint256 amount, uint256 fee);
    event FeeWithdrawn(address indexed to, uint256 amount);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event CreatorRemoved(address indexed creator);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FEE_MANAGER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function registerCreator(string memory name) external whenNotPaused {
        require(!creators[msg.sender].isRegistered, "Already registered");
        require(bytes(name).length > 0, "Name cannot be empty");
        creators[msg.sender] = Creator(name, true, 0);
        emit CreatorRegistered(msg.sender, name);
    }

    function tipCreator(address payable creatorAddress) external payable whenNotPaused nonReentrant {
        require(creators[creatorAddress].isRegistered, "Creator not registered");
        require(msg.value > 0, "Tip must be greater than 0");
        uint256 fee = (msg.value * platformFee) / 100;
        uint256 tipAmount = msg.value - fee;
        collectedFees += fee;
        creators[creatorAddress].totalTipsReceived += tipAmount;
        creatorAddress.transfer(tipAmount);
        emit TipSent(msg.sender, creatorAddress, tipAmount, fee);
    }

    function withdrawFees(address payable to) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(collectedFees > 0, "No fees to withdraw");
        uint256 amount = collectedFees;
        collectedFees = 0;
        to.transfer(amount);
        emit FeeWithdrawn(to, amount);
    }

    function updatePlatformFee(uint256 newFee) external onlyRole(FEE_MANAGER_ROLE) {
        require(newFee <= 20, "Fee cannot exceed 20%");
        emit PlatformFeeUpdated(platformFee, newFee);
        platformFee = newFee;
    }

    function removeCreator(address creator) external onlyRole(ADMIN_ROLE) {
        require(creators[creator].isRegistered, "Creator not registered");
        delete creators[creator];
        emit CreatorRemoved(creator);
    }

    function pause() external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    receive() external payable {}
}
