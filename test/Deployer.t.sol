// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SynthereumFinder} from "../src/Finder.sol"; // Assuming Finder.sol is in src directory
import {SynthereumDeployer} from "../src/Deployer.sol";
import {MockAggregator} from "../src/test/MockAggregator.sol";
import {StandardAccessControlEnumerable} from "../src/roles/StandardAccessControlEnumerable.sol";
import {SynthereumPriceFeed} from "../src/oracle/PriceFeed.sol";
import {SynthereumManager} from "../src/Manager.sol";
import {SynthereumCollateralWhitelist} from "../src/CollateralWhitelist.sol";
import {SynthereumIdentifierWhitelist} from "../src/IdentifierWhitelist.sol";
import {SynthereumFactoryVersioning} from "../src/FactoryVersioning.sol";
import {SynthereumTrustedForwarder} from "../src/TrustedForwarder.sol";
import {SynthereumChainlinkPriceFeed} from "../src/oracle/implementations/ChainlinkPriceFeed.sol";
import {SynthereumPriceFeedImplementation} from "../src/oracle/implementations/PriceFeedImplementation.sol";
import {SynthereumSyntheticTokenPermitFactory} from "../src/tokens/factories/SyntheticTokenPermitFactory.sol";


contract DeployerTest is Test {
    struct Roles {
        address admin;
        address maintainer;
        address liquidityProvider;
        address excessBeneficiary;
        address dao;
        address firstWrongAddress;
        address minter;
        address burner;
    }

    struct LendingManagerParams {
        string lendingId;
        address interestBearingToken;
        uint64 daoInterestShare;
        uint64 jrtBuybackShare;
    }

    struct PoolParams {
        uint8 version;
        address collateralToken;
        string syntheticName;
        string syntheticSymbol;
        address syntheticToken;
        StandardAccessControlEnumerable.Roles roles;
        uint64 fee;
        bytes32 priceIdentifier;
        uint128 overCollateralRequirement;
        uint64 liquidationReward;
        LendingManagerParams lendingManagerParams;
    }


    // State variables to store the values
    address public collateralAddress = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
    string public priceIdentifier = "EURUSD";
    string public syntheticName = "Citadel Synthetic Euro";
    string public syntheticSymbol = "cEUR";
    string public lendingId = "AaveV3";
    uint64 daoInterestShare = 0.1 ether;
    uint64 jrtBuybackShare = 0.6 ether;
    uint8 poolVersion;
    uint256 overCollateralisation = 0.2 ether;
    uint128 overCollateralRequirement = 0.05 ether;
    uint64 liquidationReward = 0.5 ether;
    uint64 feePercentage = 0.02 ether; // 2% fee
    uint32[2] feeProportions;
    uint256 capMintAmount = 1_000_000 ether;
    uint64 maxSpread = 0.001 ether;

    SynthereumFinder finder;
    SynthereumManager manager;

    LendingManagerParams lendingManagerParams;
    PoolParams poolParams;

    struct Fee {
     uint64 feePercentage;
     address[2] feeRecipients;
     uint32[2] feeProportions;
    }


    Roles public roles;
    Fee public fee;
    Fee public selfMintingFee;

    SynthereumDeployer deployer;

    MockAggregator mockAggregator; 
    SynthereumPriceFeed priceFeed;
    SynthereumChainlinkPriceFeed synthereumChainlinkPriceFeed;
    SynthereumSyntheticTokenPermitFactory tokenFactory;
    SynthereumTrustedForwarder forwarderInstance;
    SynthereumCollateralWhitelist collateralWhitelist;
    SynthereumIdentifierWhitelist identifierWhitelist;

    address debtTokenAddress = 0x75bd1A659bdC62e4C313950d44A2416faB43E785; //aBnbFdusd debt token
    //TODO: Finish this test with factory

    constructor() {
        roles = Roles({
            admin: address(0x2),
            maintainer: address(0x3),
            liquidityProvider: address(0x4),
            excessBeneficiary: address(0x5),
            dao: address(0x6),
            firstWrongAddress: address(0x7),
            minter: address(0x8),
            burner: address(0x9)
        });
        mockAggregator = new MockAggregator(8, 120000000);
        finder = new SynthereumFinder(SynthereumFinder.Roles(roles.admin, roles.maintainer));
        priceFeed = new SynthereumPriceFeed(finder, StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer));
        synthereumChainlinkPriceFeed = new SynthereumChainlinkPriceFeed(finder, StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer));
        feeProportions = [50, 50];
        fee = Fee(feePercentage, [roles.liquidityProvider, roles.dao], feeProportions);
        selfMintingFee = fee;
        vm.startPrank(roles.maintainer);
        priceFeed.addOracle("chainlink",address(synthereumChainlinkPriceFeed));
        maxSpread = 0.001 ether;
        synthereumChainlinkPriceFeed.setPair(priceIdentifier, SynthereumPriceFeedImplementation.Type(1), address(mockAggregator), 0, "", maxSpread);
        string[] memory emptyArray;
        priceFeed.setPair(priceIdentifier, SynthereumPriceFeed.Type(1), "chainlink", emptyArray);
        collateralWhitelist = new SynthereumCollateralWhitelist(SynthereumCollateralWhitelist.Roles(roles.admin, roles.maintainer));
        collateralWhitelist.addToWhitelist(collateralAddress);
        identifierWhitelist = new SynthereumIdentifierWhitelist(SynthereumIdentifierWhitelist.Roles(roles.admin, roles.maintainer));
        identifierWhitelist.addToWhitelist(bytes32(bytes(priceIdentifier)));
        vm.stopPrank();
    }

    function setUp() public {
        poolVersion = 6;
        lendingManagerParams = LendingManagerParams(lendingId, debtTokenAddress, daoInterestShare, jrtBuybackShare);
        poolParams = PoolParams(poolVersion, collateralAddress, syntheticName, syntheticSymbol, address(0), StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer), feePercentage, bytes32(bytes(priceIdentifier)), overCollateralRequirement, liquidationReward, lendingManagerParams);
        deployer = new SynthereumDeployer(finder, SynthereumDeployer.Roles(roles.admin, roles.maintainer));
        manager = new SynthereumManager(finder, SynthereumManager.Roles(roles.admin, roles.maintainer));
    }
    
}
