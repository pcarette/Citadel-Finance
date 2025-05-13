// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SynthereumFinder} from "../src/Finder.sol"; // Assuming Finder.sol is in src directory
import {SynthereumDeployer} from "../src/Deployer.sol";
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
import {SynthereumMultiLpLiquidityPoolFactory} from "../src/pool/MultiLpLiquidityPoolFactory.sol";
import {SynthereumMultiLpLiquidityPool} from "../src/pool/MultiLpLiquidityPool.sol";
import {LendingStorageManager} from "../src/lending-module/LendingStorageManager.sol";
import {LendingManager} from "../src/lending-module/LendingManager.sol";
import {ILendingManager} from "../src/lending-module/interfaces/ILendingManager.sol";
import {ILendingStorageManager} from "../src/lending-module/interfaces/ILendingStorageManager.sol";
import {SynthereumPoolRegistry} from "../src/registries/PoolRegistry.sol";

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
    address public collateralAddress =
        0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
    string public priceIdentifier = "EURUSD";
    string public syntheticName = "Citadel Euro";
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

    SynthereumSyntheticTokenPermitFactory tokenFactory;

    SynthereumFinder finder;
    SynthereumManager manager;
    LendingManager lendingManager;
    LendingStorageManager lendingStorageManager;
    address aggregator = 0x0bf79F617988C472DcA68ff41eFe1338955b9A80;// Chainlink bsc data feed address;
    SynthereumPriceFeed priceFeed;
    SynthereumChainlinkPriceFeed synthereumChainlinkPriceFeed;
    SynthereumMultiLpLiquidityPoolFactory poolFactory;
    SynthereumTrustedForwarder forwarderInstance;
    SynthereumCollateralWhitelist collateralWhitelist;
    SynthereumIdentifierWhitelist identifierWhitelist;
    SynthereumPoolRegistry poolRegistry;
    

    address debtTokenAddress = 0x75bd1A659bdC62e4C313950d44A2416faB43E785; //aave aBnbFdusd debt token

    //TODO: reorder all contracts declarations & deployments

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
        finder = new SynthereumFinder(
            SynthereumFinder.Roles(roles.admin, roles.maintainer)
        );
        priceFeed = new SynthereumPriceFeed(
            finder,
            StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer)
        );


        synthereumChainlinkPriceFeed = new SynthereumChainlinkPriceFeed(
            finder,
            StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer)
        );
        feeProportions = [50, 50];
        fee = Fee(
            feePercentage,
            [roles.liquidityProvider, roles.dao],
            feeProportions
        );
        selfMintingFee = fee;
        poolVersion = 1;

        vm.startPrank(roles.maintainer);

        finder.changeImplementationAddress(
            bytes32(bytes("PriceFeed")),
            address(priceFeed)
        );
        priceFeed.addOracle("chainlink", address(synthereumChainlinkPriceFeed));
        maxSpread = 0.001 ether;
        synthereumChainlinkPriceFeed.setPair(
            priceIdentifier,
            SynthereumPriceFeedImplementation.Type(1),
            aggregator,
            0,
            "",
            maxSpread
        );
        string[] memory emptyArray;
        priceFeed.setPair(
            priceIdentifier,
            SynthereumPriceFeed.Type(1),
            "chainlink",
            emptyArray
        );
        collateralWhitelist = new SynthereumCollateralWhitelist(
            SynthereumCollateralWhitelist.Roles(roles.admin, roles.maintainer)
        );
        collateralWhitelist.addToWhitelist(collateralAddress);
        finder.changeImplementationAddress(
            bytes32(bytes("CollateralWhitelist")),
            address(collateralWhitelist)
        );
        identifierWhitelist = new SynthereumIdentifierWhitelist(
            SynthereumIdentifierWhitelist.Roles(roles.admin, roles.maintainer)
        );
        identifierWhitelist.addToWhitelist(bytes32(bytes(priceIdentifier)));
        finder.changeImplementationAddress(
            bytes32(bytes("IdentifierWhitelist")),
            address(identifierWhitelist)
        );
        tokenFactory = new SynthereumSyntheticTokenPermitFactory(
            address(finder)
        );
        finder.changeImplementationAddress(
            bytes32(bytes("TokenFactory")),
            address(tokenFactory)
        );

        lendingStorageManager = new LendingStorageManager(finder);
        finder.changeImplementationAddress(
            bytes32(bytes("LendingStorageManager")),
            address(lendingStorageManager)
        );

        lendingManager = new LendingManager(finder, ILendingManager.Roles(roles.admin, roles.maintainer));
        finder.changeImplementationAddress(
            bytes32(bytes("LendingManager")),
            address(lendingManager)
        );
        ILendingStorageManager.LendingInfo memory lendingInfo = ILendingStorageManager.LendingInfo(0xe6905378F7F595704368f2295938cb844a5b7eED, ""); // address of Aavev3 pool on bsc
        lendingManager.setLendingModule("AaveV3", lendingInfo);

        poolRegistry = new SynthereumPoolRegistry(finder); 
        finder.changeImplementationAddress(
            bytes32(bytes("PoolRegistry")),
            address(poolRegistry)
        );

        manager = new SynthereumManager(
            finder,
            SynthereumManager.Roles(roles.admin, roles.maintainer)
        );

        // Update the Manager implementation address in the SynthereumFinder
        finder.changeImplementationAddress(
            bytes32(bytes("Manager")),
            address(manager)
        );
        forwarderInstance = new SynthereumTrustedForwarder();
        finder.changeImplementationAddress(
            bytes32(bytes("TrustedForwarder")),
            address(forwarderInstance)
        );

        // Deploy FactoryVersioning and set roles
        SynthereumFactoryVersioning factoryVersioning = new SynthereumFactoryVersioning(
                SynthereumFactoryVersioning.Roles(roles.admin, roles.maintainer)
            );

        SynthereumMultiLpLiquidityPool poolImplementation = new SynthereumMultiLpLiquidityPool();


        // Deploy the pool factory with the pool implementation address
        poolFactory = new SynthereumMultiLpLiquidityPoolFactory(
            address(finder),
            address(poolImplementation) // Ensure this implementation exists
        );

        // Register the pool factory in FactoryVersioning for the correct version
        factoryVersioning.setFactory(
            bytes32(bytes("PoolFactory")),
            poolVersion,
            address(poolFactory)
        );


        finder.changeImplementationAddress(
            bytes32(bytes("FactoryVersioning")),
            address(factoryVersioning)
        );


        vm.stopPrank();
    }

    function setUp() public {
        // Define pool version and lending manager parameters
        lendingManagerParams = LendingManagerParams(
            lendingId,
            debtTokenAddress,
            daoInterestShare,
            jrtBuybackShare
        );

        // Define pool parameters, setting `liquidityProvider` to `address(0)`
        poolParams = PoolParams(
            poolVersion,
            collateralAddress,
            syntheticName,
            syntheticSymbol,
            address(0), // Placeholder for liquidity provider address
            StandardAccessControlEnumerable.Roles(
                roles.admin,
                roles.maintainer
            ),
            feePercentage,
            bytes32(bytes(priceIdentifier)),
            overCollateralRequirement,
            liquidationReward,
            lendingManagerParams
        );

        // Start simulating the maintainer role
        vm.startPrank(roles.maintainer);

        // Deploy SynthereumDeployer contract with admin and maintainer roles
        deployer = new SynthereumDeployer(
            finder,
            SynthereumDeployer.Roles(roles.admin, roles.maintainer)
        );
        // Update Deployer and FactoryVersioning implementations in SynthereumFinder
        finder.changeImplementationAddress(
            bytes32(bytes("Deployer")),
            address(deployer)
        );

        // Deploy SynthereumManager contract with admin and maintainer roles

        // Stop simulating the maintainer role
        vm.stopPrank();
    }
    event PoolDeployed(uint8 indexed poolVersion, address indexed newPool);

    function testShouldDeployPool() public {
        vm.startPrank(roles.maintainer);
        vm.expectEmit(true, false, false, false);
        emit PoolDeployed(1, address(0x000000000000));
        deployer.deployPool(poolVersion, abi.encode(poolParams));
        vm.stopPrank();
    }


}
