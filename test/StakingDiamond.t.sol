// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/StakingFacet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/mocks/MockERC20.sol";
import "../contracts/mocks/MockERC721.sol";
import "../contracts/mocks/MockERC1155.sol";

contract StakingDiamondTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    StakingFacet public stakingFacet;
    ERC20Facet public erc20Facet;
    MockERC20 public stakingToken;
    MockERC721 public stakingNFT;
    MockERC1155 public stakingERC1155;
    
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy mock tokens
        stakingToken = new MockERC20("Staking Token", "STK", 1000000 ether);
        stakingNFT = new MockERC721("Staking NFT", "SNFT");
        stakingERC1155 = new MockERC1155("https://mock-uri.com/");
        
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        stakingFacet = new StakingFacet();
        erc20Facet = new ERC20Facet();
        
        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));
        
        // Add facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        
        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });
        
        // StakingFacet
        bytes4[] memory stakingSelectors = new bytes4[](9);
        stakingSelectors[0] = StakingFacet.stake.selector;
        stakingSelectors[1] = StakingFacet.stakeNFT.selector;
        stakingSelectors[2] = StakingFacet.stakeERC1155.selector;
        stakingSelectors[3] = StakingFacet.unstake.selector;
        stakingSelectors[4] = StakingFacet.unstakeNFT.selector;
        stakingSelectors[5] = StakingFacet.unstakeERC1155.selector;
        stakingSelectors[6] = StakingFacet.claimRewards.selector;
        stakingSelectors[7] = StakingFacet.getStakedAmount.selector;
        stakingSelectors[8] = StakingFacet.getPendingRewards.selector;
        
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: stakingSelectors
        });
        
        // ERC20Facet
        bytes4[] memory erc20Selectors = new bytes4[](9);
        erc20Selectors[0] = ERC20Facet.name.selector;
        erc20Selectors[1] = ERC20Facet.symbol.selector;
        erc20Selectors[2] = ERC20Facet.decimals.selector;
        erc20Selectors[3] = ERC20Facet.totalSupply.selector;
        erc20Selectors[4] = ERC20Facet.balanceOf.selector;
        erc20Selectors[5] = ERC20Facet.transfer.selector;
        erc20Selectors[6] = ERC20Facet.allowance.selector;
        erc20Selectors[7] = ERC20Facet.approve.selector;
        erc20Selectors[8] = ERC20Facet.transferFrom.selector;
        
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: erc20Selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        
        // Initialize facets
        ERC20Facet(address(diamond)).initialize("Staking Reward Token", "SRT", 18);
        StakingFacet(address(diamond)).initialize(address(stakingToken), address(stakingNFT), address(stakingERC1155));
        
        // Mint tokens to users
        stakingToken.mint(user1, 1000 ether);
        stakingToken.mint(user2, 1000 ether);
        
        stakingNFT.mint(user1);
        stakingNFT.mint(user2);
        
        stakingERC1155.mint(user1, 1, 100, "");
        stakingERC1155.mint(user2, 1, 100, "");
    }
    
    function testStakeERC20() public {
        uint256 amount = 100 ether;
        vm.prank(user1);
        stakingToken.approve(address(diamond), amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stake(amount);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, amount);
    }
    
    function testUnstakeERC20() public {
        uint256 amount = 100 ether;
        vm.prank(user1);
        stakingToken.approve(address(diamond), amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stake(amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).unstake(amount);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, 0);
    }
    
    function testStakeNFT() public {
        vm.prank(user1);
        stakingNFT.approve(address(diamond), 1);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stakeNFT(1);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, 1 ether);
    }
    
    function testUnstakeNFT() public {
        vm.prank(user1);
        stakingNFT.approve(address(diamond), 1);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stakeNFT(1);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).unstakeNFT(1);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, 0);
    }
    
    function testStakeERC1155() public {
        uint256 amount = 50;
        vm.prank(user1);
        stakingERC1155.setApprovalForAll(address(diamond), true);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stakeERC1155(1, amount);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, amount);
    }
    
    function testUnstakeERC1155() public {
        uint256 amount = 50;
        vm.prank(user1);
        stakingERC1155.setApprovalForAll(address(diamond), true);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stakeERC1155(1, amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).unstakeERC1155(1, amount);
        
        uint256 stakedAmount = StakingFacet(address(diamond)).getStakedAmount(user1);
        assertEq(stakedAmount, 0);
    }
    
    function testRewards() public {
        uint256 amount = 100 ether;
        vm.prank(user1);
        stakingToken.approve(address(diamond), amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stake(amount);
        
        // Advance time by 1 day
        vm.warp(block.timestamp + 1 days);
        
        uint256 pendingRewards = StakingFacet(address(diamond)).getPendingRewards(user1);
        assertGt(pendingRewards, 0);
        
        uint256 initialBalance = ERC20Facet(address(diamond)).balanceOf(user1);
        vm.prank(user1);
        StakingFacet(address(diamond)).claimRewards();
        uint256 finalBalance = ERC20Facet(address(diamond)).balanceOf(user1);
        
        assertGt(finalBalance, initialBalance);
    }
    
    function testRewardDecay() public {
        uint256 amount = 100 ether;
        vm.prank(user1);
        stakingToken.approve(address(diamond), amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stake(amount);
        
        // Advance time by 1 year
        vm.warp(block.timestamp + 365 days);
        
        uint256 pendingRewards = StakingFacet(address(diamond)).getPendingRewards(user1);
        uint256 expectedRewards = (amount * 1 ether * 365 days) / 1 ether;
        uint256 decayedRewards = expectedRewards * 9000 / 10000; // 10% decay rate
        
        assertApproxEqAbs(pendingRewards, decayedRewards, 0.1 ether);
    }
    
    function testTransferRewards() public {
        uint256 amount = 100 ether;
        vm.prank(user1);
        stakingToken.approve(address(diamond), amount);
        
        vm.prank(user1);
        StakingFacet(address(diamond)).stake(amount);
        
        // Advance time to generate rewards
        vm.warp(block.timestamp + 1 days);
        vm.prank(user1);
        StakingFacet(address(diamond)).claimRewards();
        
        uint256 rewardAmount = ERC20Facet(address(diamond)).balanceOf(user1);
        vm.prank(user1);
        ERC20Facet(address(diamond)).transfer(user2, rewardAmount);
        
        uint256 user2Balance = ERC20Facet(address(diamond)).balanceOf(user2);
        assertEq(user2Balance, rewardAmount);
    }
} 