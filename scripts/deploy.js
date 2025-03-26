const { ethers } = require("hardhat");

async function main() {
  // Deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const diamondCutFacet = await DiamondCutFacet.deploy();
  await diamondCutFacet.deployed();
  console.log("DiamondCutFacet deployed to:", diamondCutFacet.address);

  // Deploy DiamondLoupeFacet
  const DiamondLoupeFacet = await ethers.getContractFactory("DiamondLoupeFacet");
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();
  await diamondLoupeFacet.deployed();
  console.log("DiamondLoupeFacet deployed to:", diamondLoupeFacet.address);

  // Deploy StakingFacet
  const StakingFacet = await ethers.getContractFactory("StakingFacet");
  const stakingFacet = await StakingFacet.deploy();
  await stakingFacet.deployed();
  console.log("StakingFacet deployed to:", stakingFacet.address);

  // Deploy ERC20Facet
  const ERC20Facet = await ethers.getContractFactory("ERC20Facet");
  const erc20Facet = await ERC20Facet.deploy();
  await erc20Facet.deployed();
  console.log("ERC20Facet deployed to:", erc20Facet.address);

  // Deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(
    (await ethers.getSigners())[0].address,
    diamondCutFacet.address
  );
  await diamond.deployed();
  console.log("Diamond deployed to:", diamond.address);

  // Create DiamondCut
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.address);

  // Add facets
  const cut = [
    {
      facetAddress: diamondLoupeFacet.address,
      action: 0, // Add
      functionSelectors: [
        "0xcdffacc6", // facets()
        "0x52ef6b2c", // facetFunctionSelectors(address)
        "0xadfca15e", // facetAddresses()
        "0x7a0ed627", // facetAddress(bytes4)
      ],
    },
    {
      facetAddress: stakingFacet.address,
      action: 0, // Add
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
      action: 0, // Add
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

  // Perform diamond cut
  await diamondCut.diamondCut(cut, ethers.constants.AddressZero, "0x");
  console.log("Diamond cut completed");

  // Initialize facets
  const staking = await ethers.getContractAt("StakingFacet", diamond.address);
  const erc20 = await ethers.getContractAt("ERC20Facet", diamond.address);

  // Initialize ERC20
  await erc20.initialize("Staking Reward Token", "SRT", 18);
  console.log("ERC20 initialized");

  // Initialize Staking
  // Replace these addresses with actual token addresses
  const stakingToken = "0x..."; // ERC20 token address
  const stakingNFT = "0x..."; // ERC721 token address
  const stakingERC1155 = "0x..."; // ERC1155 token address
  await staking.initialize(stakingToken, stakingNFT, stakingERC1155);
  console.log("Staking initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 