// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SynthereumFinder} from "../src/Finder.sol"; // Assuming Finder.sol is in src directory
import {MockAggregator} from "../src/test/MockAggregator.sol";
import {StandardAccessControlEnumerable} from "../src/roles/StandardAccessControlEnumerable.sol";
import {SynthereumPriceFeed} from "../src/oracle/PriceFeed.sol";
import {SynthereumManager} from "../src/Manager.sol";
import {SynthereumCollateralWhitelist} from "../src/CollateralWhitelist.sol";
import {SynthereumIdentifierWhitelist} from "../src/IdentifierWhitelist.sol";
import {SynthereumFactoryVersioning} from "../src/FactoryVersioning.sol";
import {SynthereumTrustedForwarder} from "../src/TrustedForwarder.sol";
import {SynthereumChainlinkPriceFeed} from "../src/oracle/implementations/ChainlinkPriceFeed.sol";
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


    // State variables to store the values
    address public collateralAddress;
    string public priceIdentifier = "EURUSD";
    string public syntheticName = "Citadel Synthetic Euro";
    string public syntheticSymbol = "cEUR";
    string public lendingId = "AaveV3";
    uint256 daoInterestShare = 0.1 ether;
    SynthereumFinder finder;
    address manager;
    SynthereumManager managerContract;
    uint8 poolVersion;
    uint256 overCollateralisation = 0.2 ether;
    uint256 overCollateralRequirement = 0.05 ether;
    uint256 liquidationReward = 0.5 ether;
    uint64 feePercentage = 0.02 ether; // 2% fee
    uint32[2] feeProportions;
    uint256 capMintAmount = 1_000_000 ether;
    uint64 maxSpread = 0.001 ether;

    struct Fee {
     uint64 feePercentage;
     address[2] feeRecipients;
     uint32[2] feeProportions;
    }


    Roles public roles;
    Fee public fee;
    Fee public selfMintingFee;

    MockAggregator mockAggregator; 
    SynthereumPriceFeed priceFeed;
    SynthereumChainlinkPriceFeed synthereumChainlinkPriceFeed;
    SynthereumSyntheticTokenPermitFactory tokenFactory;
    SynthereumTrustedForwarder forwarderInstance;

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
        finder = new SynthereumFinder(SynthereumFinder.Roles(roles.admin, roles.maintainer));
        collateralAddress = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
        mockAggregator = new MockAggregator(8, 120000000);
        priceFeed = new SynthereumPriceFeed(finder, StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer));
        feeProportions = [50, 50];
        fee = Fee(feePercentage, [roles.liquidityProvider, roles.dao], feeProportions);
        selfMintingFee = fee;
    }
}
