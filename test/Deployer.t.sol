// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SynthereumFinder} from "../src/Finder.sol"; // Assuming Finder.sol is in src directory
import {MockAggregator} from "../src/test/MockAggregator.sol";
import {SynthereumPriceFeed} from "../src/oracle/PriceFeed.sol";
import {SynthereumManager} from "../src/Manager.sol";

contract DeployerTest is Test {
    struct Roles {
        address admin;
        address maintainer;
        address liquidityProvider;
    }

    // State variables to store the values
    address public collateralAddress;
    string public priceIdentifier = "EURUSD";
    string public syntheticName = "Citadel Synthetic Euro";
    string public syntheticSymbol = "cEUR";
    string public lendingId = "AaveV3";
    uint256 daoInterestShare = 0.1 ether;
    address synthereumFinderAddress;
    address manager;
    SynthereumManager managerContract;
    uint8 poolVersion;
    uint256 overCollateralisation = 0.2 ether;
    uint256 overCollateralRequirement = 0.05 ether;
    uint256 liquidationReward = 0.5 ether;


    Roles public roles;

    MockAggregator mockAggregator = new MockAggregator(8, 120000000);

    //TODO: Finish this test with factory

    constructor() {
        collateralAddress = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
        roles = Roles({
            admin: address(0x2),
            maintainer: address(0x3),
            liquidityProvider: address(0x4)
        });
    }
}
