const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("StakingDiamond", function () {
  let diamond;
  let diamondCutFacet;
  let diamondLoupeFacet;
  let stakingFacet;
  let erc20Facet;
  let stakingToken;
  let stakingNFT;
  let stakingERC1155;
  let owner;
  let user1;
  let user2;
  
  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
    // Deploy mock tokens
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    stakingToken = await MockERC20.deploy("Staking Token", "STK", ethers.utils.parseEther("1000000"));
    await stakingToken.deployed();
    
    const MockERC721 = await ethers.getContractFactory("MockERC721");
    stakingNFT = await MockERC721.deploy("Staking NFT", "SNFT");
    await stakingNFT.deployed();
    
    const MockERC1155 = await ethers.getContractFactory("MockERC1155");
    stakingERC1155 = await MockERC1155.deploy("https://mock-uri.com/");
    await stakingERC1155.deployed();
    
    // Deploy facets
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
    diamondCutFacet = await DiamondCutFacet.deploy();
    await diamondCutFacet.deployed();
    
    const DiamondLoupeFacet = await ethers.getContractFactory("DiamondLoupeFacet");
    diamondLoupeFacet = await DiamondLoupeFacet.deploy();
    await diamondLoupeFacet.deployed();
    
    const StakingFacet = await ethers.getContractFactory("StakingFacet");
    stakingFacet = await StakingFacet.deploy();
    await stakingFacet.deployed();
    
    const ERC20Facet = await ethers.getContractFactory("ERC20Facet");
    erc20Facet = await ERC20Facet.deploy();
    await erc20Facet.deployed();
    
    // Deploy Diamond
    const Diamond = await ethers.getContractFactory("Diamond");
    diamond = await Diamond.deploy(owner.address, diamondCutFacet.address);
    await diamond.deployed();
    
    // Create DiamondCut
    const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);
    
    // Add facets
    const cut = [
      {
        facetAddress: diamondLoupeFacet.address,
        action: 0,
        functionSelectors: [
          "0xcdffacc6", // facets()
          "0x52ef6b2c", // facetFunctionSelectors(address)
          "0xadfca15e", // facetAddresses()
          "0x7a0ed627", // facetAddress(bytes4)
        ],
      },
      {
        facetAddress: stakingFacet.address,
        action: 0,
        functionSelectors: [
          "0x2e1a7d4d", // stake(uint256)
          "0x4e71d92d", // stakeNFT(uint256)
          "0x2b67b570", // stakeERC1155(uint256,uint256)
          "0x2e17de78", // unstake(uint256)
          "0x9b9b0b36", // unstakeNFT(uint256)
          "0x2b67b570", // unstakeERC1155(uint256,uint256)
          "0x372500ab", // claimRewards()
          "0x2f940c70", // getStakedAmount(address)
          "0x8f32d59b", // getPendingRewards(address)
        ],
      },
      {
        facetAddress: erc20Facet.address,
        action: 0,
        functionSelectors: [
          "0x06fdde03", // name()
          "0x95d89b41", // symbol()
          "0x313ce567", // decimals()
          "0x18160ddd", // totalSupply()
          "0x70a08231", // balanceOf(address)
          "0xa9059cbb", // transfer(address,uint256)
          "0xdd62ed3e", // allowance(address,address)
          "0x095ea7b3", // approve(address,uint256)
          "0x23b872dd", // transferFrom(address,address,uint256)
        ],
      },
    ];
    
    await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
    
    // Initialize facets
    const staking = await ethers.getContractAt("StakingFacet", diamond.address);
    const erc20 = await ethers.getContractAt("ERC20Facet", diamond.address);
    
    await erc20.initialize("Staking Reward Token", "SRT", 18);
    await staking.initialize(stakingToken.address, stakingNFT.address, stakingERC1155.address);
    
    // Mint tokens to users
    await stakingToken.mint(user1.address, ethers.utils.parseEther("1000"));
    await stakingToken.mint(user2.address, ethers.utils.parseEther("1000"));
    
    await stakingNFT.mint(user1.address, 1);
    await stakingNFT.mint(user2.address, 2);
    
    await stakingERC1155.mint(user1.address, 1, 100, "0x");
    await stakingERC1155.mint(user2.address, 1, 100, "0x");
  });
  
  describe("ERC20 Staking", function () {
    it("Should stake ERC20 tokens", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(amount);
    });
    
    it("Should unstake ERC20 tokens", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      await diamond.connect(user1).unstake(amount);
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(0);
    });
  });
  
  describe("ERC721 Staking", function () {
    it("Should stake ERC721 tokens", async function () {
      await stakingNFT.connect(user1).approve(diamond.address, 1);
      await diamond.connect(user1).stakeNFT(1);
      
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(ethers.utils.parseEther("1"));
    });
    
    it("Should unstake ERC721 tokens", async function () {
      await stakingNFT.connect(user1).approve(diamond.address, 1);
      await diamond.connect(user1).stakeNFT(1);
      
      await diamond.connect(user1).unstakeNFT(1);
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(0);
    });
  });
  
  describe("ERC1155 Staking", function () {
    it("Should stake ERC1155 tokens", async function () {
      const amount = 50;
      await stakingERC1155.connect(user1).setApprovalForAll(diamond.address, true);
      await diamond.connect(user1).stakeERC1155(1, amount);
      
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(amount);
    });
    
    it("Should unstake ERC1155 tokens", async function () {
      const amount = 50;
      await stakingERC1155.connect(user1).setApprovalForAll(diamond.address, true);
      await diamond.connect(user1).stakeERC1155(1, amount);
      
      await diamond.connect(user1).unstakeERC1155(1, amount);
      const stakedAmount = await diamond.getStakedAmount(user1.address);
      expect(stakedAmount).to.equal(0);
    });
  });
  
  describe("Rewards", function () {
    it("Should calculate rewards correctly", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      // Advance time by 1 day
      await time.increase(86400);
      
      const pendingRewards = await diamond.getPendingRewards(user1.address);
      expect(pendingRewards).to.be.gt(0);
    });
    
    it("Should claim rewards", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      // Advance time by 1 day
      await time.increase(86400);
      
      const initialBalance = await diamond.balanceOf(user1.address);
      await diamond.connect(user1).claimRewards();
      const finalBalance = await diamond.balanceOf(user1.address);
      
      expect(finalBalance).to.be.gt(initialBalance);
    });
    
    it("Should apply decay rate to rewards", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      // Advance time by 1 year
      await time.increase(31536000);
      
      const pendingRewards = await diamond.getPendingRewards(user1.address);
      const expectedRewards = (amount.mul(ethers.utils.parseEther("1")).mul(31536000)).div(ethers.utils.parseEther("1"));
      const decayedRewards = expectedRewards.mul(9000).div(10000); // 10% decay rate
      
      expect(pendingRewards).to.be.closeTo(decayedRewards, ethers.utils.parseEther("0.1"));
    });
  });
  
  describe("ERC20 Token", function () {
    it("Should transfer reward tokens", async function () {
      const amount = ethers.utils.parseEther("100");
      await stakingToken.connect(user1).approve(diamond.address, amount);
      await diamond.connect(user1).stake(amount);
      
      // Advance time to generate rewards
      await time.increase(86400);
      await diamond.connect(user1).claimRewards();
      
      const rewardAmount = await diamond.balanceOf(user1.address);
      await diamond.connect(user1).transfer(user2.address, rewardAmount);
      
      const user2Balance = await diamond.balanceOf(user2.address);
      expect(user2Balance).to.equal(rewardAmount);
    });
  });
}); 