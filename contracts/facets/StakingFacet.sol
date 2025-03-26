// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract StakingFacet {
    AppStorage internal s;
    
    function initialize(
        address _stakingToken,
        address _stakingNFT,
        address _stakingERC1155
    ) external {
        s.stakingToken = IERC20(_stakingToken);
        s.stakingNFT = IERC721(_stakingNFT);
        s.stakingERC1155 = IERC1155(_stakingERC1155);
        s.rewardRate = 1e18; // 1 token per second
        s.decayRate = 1000; // 10% per year
        s.lastUpdateTime = block.timestamp;
    }
    
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from user
        require(s.stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update user's staking info
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        userInfo.amount += amount;
        userInfo.startTime = block.timestamp;
        userInfo.lastRewardTime = block.timestamp;
        
        s.totalStaked += amount;
        emit Staked(msg.sender, amount);
    }
    
    function stakeNFT(uint256 tokenId) external {
        // Transfer NFT from user
        s.stakingNFT.transferFrom(msg.sender, address(this), tokenId);
        
        // Update user's staking info (treating 1 NFT as 1e18 tokens)
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        userInfo.amount += 1e18;
        userInfo.startTime = block.timestamp;
        userInfo.lastRewardTime = block.timestamp;
        
        s.totalStaked += 1e18;
        emit Staked(msg.sender, 1e18);
    }
    
    function stakeERC1155(uint256 tokenId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer ERC1155 tokens from user
        s.stakingERC1155.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        // Update user's staking info
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        userInfo.amount += amount;
        userInfo.startTime = block.timestamp;
        userInfo.lastRewardTime = block.timestamp;
        
        s.totalStaked += amount;
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) external {
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        require(userInfo.amount >= amount, "Insufficient staked amount");
        
        // Claim any pending rewards
        _claimRewards();
        
        // Update user's staking info
        userInfo.amount -= amount;
        s.totalStaked -= amount;
        
        // Transfer tokens back to user
        require(s.stakingToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit Unstaked(msg.sender, amount);
    }
    
    function unstakeNFT(uint256 tokenId) external {
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        require(userInfo.amount >= 1e18, "Insufficient staked amount");
        
        // Claim any pending rewards
        _claimRewards();
        
        // Update user's staking info
        userInfo.amount -= 1e18;
        s.totalStaked -= 1e18;
        
        // Transfer NFT back to user
        s.stakingNFT.transferFrom(address(this), msg.sender, tokenId);
        
        emit Unstaked(msg.sender, 1e18);
    }
    
    function unstakeERC1155(uint256 tokenId, uint256 amount) external {
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        require(userInfo.amount >= amount, "Insufficient staked amount");
        
        // Claim any pending rewards
        _claimRewards();
        
        // Update user's staking info
        userInfo.amount -= amount;
        s.totalStaked -= amount;
        
        // Transfer ERC1155 tokens back to user
        s.stakingERC1155.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        
        emit Unstaked(msg.sender, amount);
    }
    
    function claimRewards() external {
        _claimRewards();
    }
    
    function _claimRewards() internal {
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[msg.sender];
        if (userInfo.amount == 0) return;
        
        uint256 timeElapsed = block.timestamp - userInfo.lastRewardTime;
        uint256 rewards = (userInfo.amount * s.rewardRate * timeElapsed) / 1e18;
        
        // Apply decay rate
        uint256 decayedRewards = rewards * (10000 - s.decayRate) / 10000;
        
        if (decayedRewards > 0) {
            // Mint rewards to user
            s.balances[msg.sender] += decayedRewards;
            s.totalSupply += decayedRewards;
            
            emit RewardsClaimed(msg.sender, decayedRewards);
        }
        
        userInfo.lastRewardTime = block.timestamp;
    }
    
    function getStakedAmount(address user) external view returns (uint256) {
        return s.stakingInfo[user].amount;
    }
    
    function getPendingRewards(address user) external view returns (uint256) {
        AppStorage.StakingInfo storage userInfo = s.stakingInfo[user];
        if (userInfo.amount == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - userInfo.lastRewardTime;
        uint256 rewards = (userInfo.amount * s.rewardRate * timeElapsed) / 1e18;
        
        return rewards * (10000 - s.decayRate) / 10000;
    }
} 