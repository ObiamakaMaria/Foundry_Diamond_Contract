// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Events
event Staked(address indexed user, uint256 amount);
event Unstaked(address indexed user, uint256 amount);
event RewardsClaimed(address indexed user, uint256 amount);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

struct StakingInfo {
    uint256 amount;
    uint256 startTime;
    uint256 lastRewardTime;
    uint256 rewardDebt;
}

struct AppStorage {
    // ERC20 token being staked
    IERC20 stakingToken;
    // ERC721 token being staked
    IERC721 stakingNFT;
    // ERC1155 token being staked
    IERC1155 stakingERC1155;
    
    // Staking parameters
    uint256 totalStaked;
    uint256 rewardRate; // tokens per second
    uint256 decayRate; // percentage per year (e.g., 1000 = 10%)
    uint256 lastUpdateTime;
    
    // User staking info
    mapping(address => StakingInfo) stakingInfo;
    
    // ERC20 token info
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
} 