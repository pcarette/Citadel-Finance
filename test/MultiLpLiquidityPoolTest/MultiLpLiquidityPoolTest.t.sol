// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Test.sol";

import {SynthereumFinder} from "../../src/Finder.sol"; // Assuming Finder.sol is in src directory
import {SynthereumDeployer} from "../../src/Deployer.sol";
import {StandardAccessControlEnumerable} from "../../src/roles/StandardAccessControlEnumerable.sol";
import {SynthereumPriceFeed} from "../../src/oracle/PriceFeed.sol";
import {SynthereumManager} from "../../src/Manager.sol";
import {SynthereumCollateralWhitelist} from "../../src/CollateralWhitelist.sol";
import {SynthereumIdentifierWhitelist} from "../../src/IdentifierWhitelist.sol";
import {SynthereumFactoryVersioning} from "../../src/FactoryVersioning.sol";
import {SynthereumTrustedForwarder} from "../../src/TrustedForwarder.sol";
import {SynthereumChainlinkPriceFeed} from "../../src/oracle/implementations/ChainlinkPriceFeed.sol";
import {SynthereumPriceFeedImplementation} from "../../src/oracle/implementations/PriceFeedImplementation.sol";
import {SynthereumSyntheticTokenPermitFactory} from "../../src/tokens/factories/SyntheticTokenPermitFactory.sol";
import {SynthereumMultiLpLiquidityPoolFactory} from "../../src/pool/MultiLpLiquidityPoolFactory.sol";
import {SynthereumMultiLpLiquidityPool} from "../../src/pool/MultiLpLiquidityPool.sol";
import {LendingStorageManager} from "../../src/lending-module/LendingStorageManager.sol";
import {LendingManager} from "../../src/lending-module/LendingManager.sol";
import {ILendingManager} from "../../src/lending-module/interfaces/ILendingManager.sol";
import {ILendingStorageManager} from "../../src/lending-module/interfaces/ILendingStorageManager.sol";
import {SynthereumPoolRegistry} from "../../src/registries/PoolRegistry.sol";

import { IERC20 } from "lib/forge-std/src/interfaces/IERC20.sol";
import {ISynthereumMultiLpLiquidityPool} from "../../src/pool/interfaces/IMultiLpLiquidityPool.sol";
import {IStandardERC20} from "../../src/base/interfaces/IStandardERC20.sol";
import {IMintableBurnableERC20} from "../../src/tokens/interfaces/IMintableBurnableERC20.sol";
import {CompoundModule} from "../../src/lending-module/lending-modules/Compound.sol";



contract MultiLpLiquidityPool_Test is Test {
    struct Roles {
        address admin;
        address maintainer;
        address[] liquidityProviders;
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
    string public lendingId = "Compound";
    uint64 daoInterestShare = 0.1 ether;
    uint64 jrtBuybackShare = 0.6 ether;
    uint8 poolVersion;
    uint128 overCollateralRequirement = 0.05 ether;
    uint64 liquidationReward = 0.5 ether;
    uint64 feePercentage = 0.002 ether; // 0.2% fee
    uint32[2] feeProportions;
    uint256 capMintAmount = 1_000_000 ether;
    uint64 maxSpread = 0.001 ether;

    address debtTokenAddress = 0xC4eF4229FEc74Ccfe17B2bdeF7715fAC740BA0ba; // aave aBnbFdusd debt token



    LendingManagerParams lendingManagerParams;
    PoolParams poolParams;

    event PoolDeployed(uint8 indexed poolVersion, address indexed newPool);

    CompoundModule venusModule;


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
    SynthereumFactoryVersioning factoryVersioning;
    SynthereumMultiLpLiquidityPool pool;
    IERC20 synthToken;


    address[] lps;
    


    constructor () {
        lps.push(address(0x4));
        lps.push(address(0x44));
        roles = Roles({
            admin: address(0x2),
            maintainer: address(0x3),
            liquidityProviders: lps,
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
        poolVersion = 1;
        vm.startPrank(roles.maintainer);

        synthereumChainlinkPriceFeed = new SynthereumChainlinkPriceFeed(
            finder,
            StandardAccessControlEnumerable.Roles(roles.admin, roles.maintainer)
        );

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
        
        venusModule = new CompoundModule();

        ILendingStorageManager.LendingInfo memory lendingInfo = ILendingStorageManager.LendingInfo(address(venusModule), ""); // address of venus pool on bsc

        lendingManager.setLendingModule("Compound", lendingInfo);

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
        factoryVersioning = new SynthereumFactoryVersioning(
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

        // ! Arret ici 

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


        //! Fin de l'arret


        vm.stopPrank();

    }
    
    modifier whenTheProtocolWantsToCreateAPool() {
        // it should deploy the pool implementation correctly
        vm.prank(roles.maintainer);
         vm.expectEmit(true, false, false, false);
        emit PoolDeployed(1, address(0x000000000000));
        pool = SynthereumMultiLpLiquidityPool(address(deployer.deployPool(poolVersion, abi.encode(poolParams))));
        _; 
    }

    modifier whenPoolIsInitialized() {
        // it should deploy the pool implementation correctly
        // vm.startPrank(roles.maintainer);
        //  vm.expectEmit(true, false, false, false);
        // emit PoolDeployed(1, address(0x000000000000));
        // pool = SynthereumMultiLpLiquidityPool(address(deployer.deployPool(poolVersion, abi.encode(poolParams))));
        // vm.stopPrank();
        _;
    }

    function test_WhenPoolIsInitialized() external whenTheProtocolWantsToCreateAPool whenPoolIsInitialized {
        //Check version
        assertEq(pool.version(), poolVersion, "Wrong version");
        //Check finder
        assertEq(address(pool.synthereumFinder()), address(finder), "Wrong finder");
        //Check collateral
        assertEq(address(pool.collateralToken()), collateralAddress, "Wrong collateral");
        //Check synthetic name
        synthToken = IERC20(address(pool.syntheticToken()));
        assertEq(synthToken.name(), syntheticName, "Wrong synthetic name");
        //Check synthetic symbol
        assertEq(synthToken.symbol(), syntheticSymbol, "Wrong synthetic symbol");
        //Check lendingId 
        (string memory storedLendingId, ) = pool.lendingProtocolInfo();
        assertEq(storedLendingId, lendingId, "Wrong lendingId");
        //Check overcollateral 
        assertEq(pool.collateralRequirement(), 1 ether + overCollateralRequirement, "Wrong overCollateral");
        //Check liquidation reward 
        assertEq(pool.liquidationReward(), liquidationReward, "Wrong liquidation reward");
        //Check fee percentage 
        assertEq(pool.feePercentage(), feePercentage, "Wrong fee percentage");
    }

    function test_GivenInitializingTheLogicContractDirectly()
        external
        whenTheProtocolWantsToCreateAPool
        whenPoolIsInitialized
    {
      
    }

    function test_GivenRe_initializingAnAlreadyInitializedPool()
        external
        whenTheProtocolWantsToCreateAPool
        whenPoolIsInitialized
    {
        // it should revert with "already-initialized"
          ISynthereumMultiLpLiquidityPool.InitializationParams memory initialisationParams = ISynthereumMultiLpLiquidityPool.InitializationParams({
            finder: finder,
            version: poolVersion,
            collateralToken: IStandardERC20(address(pool.collateralToken())),
            syntheticToken: IMintableBurnableERC20(address(pool.syntheticToken())),
            roles: ISynthereumMultiLpLiquidityPool.Roles({
                admin: roles.admin,
                maintainer: roles.maintainer
            }),
            fee: feePercentage,
            priceIdentifier: bytes32(bytes(priceIdentifier)),
            overCollateralRequirement: overCollateralRequirement,
            liquidationReward: liquidationReward,
            lendingModuleId: lendingId
        });
        
        vm.expectRevert("Pool already initialized");
        vm.prank(roles.maintainer);
        pool.initialize(initialisationParams);
        // it should revert with "initializer-disabled"
    }

    function test_GivenSecondAttemptToRe_initialize()
        external
        whenTheProtocolWantsToCreateAPool
        whenPoolIsInitialized
    {
        // it should revert again
    }

    function test_GivenAnUnexpectedFailure() external whenTheProtocolWantsToCreateAPool whenPoolIsInitialized {
        // it should revert with fallback error
        // ? it should revert when collateral amount is zero during deployment
        vm.startPrank(roles.maintainer);
        PoolParams memory wrongPoolParams = poolParams;
        wrongPoolParams.overCollateralRequirement = 0;
        vm.expectRevert("Overcollateral requirement must be bigger than 0%");
        deployer.deployPool(poolVersion, abi.encode(wrongPoolParams));
        vm.stopPrank();
    }

    modifier whenLiquidityProviderRegistration() {
        // it should deploy the pool implementation correctly
        vm.prank(roles.maintainer);
         vm.expectEmit(true, false, false, false);
        emit PoolDeployed(1, address(0x000000000000));
        pool = SynthereumMultiLpLiquidityPool(address(deployer.deployPool(poolVersion, abi.encode(poolParams))));
        _;
    }

    function test_WhenLiquidityProviderRegistration()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderRegistration
    {
        // it should allow maintainer to register new LP
        vm.prank(roles.maintainer);
        pool.registerLP(lps[0]);
    }

    function test_GivenSenderIsNotTheMaintainer()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderRegistration
    {
        // it should revert with "unauthorized"
        vm.expectRevert("Sender must be the maintainer");
        vm.prank(roles.firstWrongAddress);
        pool.registerLP(lps[0]);
    }

    function test_GivenLPIsAlreadyRegistered()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderRegistration
    {
        vm.startPrank(roles.maintainer);
        pool.registerLP(lps[0]);
        // it should revert with "already-registered"
        vm.expectRevert("LP already registered");
        pool.registerLP(lps[0]);
        vm.stopPrank();
    }

    modifier whenLiquidityProviderActivation() {
        //Register first address before activation
        // vm.prank(roles.maintainer);
        // pool = SynthereumMultiLpLiquidityPool(address(deployer.deployPool(poolVersion, abi.encode(poolParams))));

        vm.prank(roles.maintainer);
        pool.registerLP(lps[0]);

        for (uint8 i = 0; i < lps.length ; ++i) {
            deal(collateralAddress, lps[i], 100 ether);
        }
        _;
    }

    //We'll need thoses variables for the rest of the tests
    IERC20 CollateralToken = IERC20(collateralAddress);
    uint256 collateralAmount = 1 ether;
    uint128 overCollateralization = 1 ether;

    function test_WhenLiquidityProviderActivation()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {

        // it should activate LP when no LPs are active
        vm.startPrank(lps[0]);
        CollateralToken.approve(address(pool), collateralAmount);
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();
        // it should activate LP when others are already active
        vm.prank(roles.maintainer);
        pool.registerLP(lps[1]);

        vm.startPrank(lps[1]);
        CollateralToken.approve(address(pool), collateralAmount);
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();

    }

    function test_GivenUnregisteredSender()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {
        // it should revert with "not-registered"
        vm.startPrank(lps[1]);
        CollateralToken.approve(address(pool), collateralAmount);

        vm.expectRevert("Sender must be a registered LP");
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();
    }

    function test_GivenCollateralAmountIsZero()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {
        // it should revert with "zero-collateral"
        vm.startPrank(lps[0]);
        collateralAmount = 0;
        CollateralToken.approve(address(pool), collateralAmount);

        vm.expectRevert("No collateral deposited");
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();
    }

    function test_GivenUndercollateralizationAtActivation()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {
        // it should revert with "insufficient-collateral"
        vm.startPrank(lps[0]);
        overCollateralization = 0.045 ether;
        CollateralToken.approve(address(pool), collateralAmount);

        vm.expectRevert("Overcollateralization must be bigger than overcollateral requirement");
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();
    }

    function test_GivenLPAlreadyActiveTriesToActivateAgain()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {
        // it should revert with "already-active"
        vm.startPrank(lps[0]);
        CollateralToken.approve(address(pool), 2 * collateralAmount);
        pool.activateLP(collateralAmount, overCollateralization);
        vm.expectRevert("LP already active");
        pool.activateLP(collateralAmount, overCollateralization);
        vm.stopPrank();
    }

    function test_GivenQueryingInfoForInactiveLP()
        external
        whenTheProtocolWantsToCreateAPool
        whenLiquidityProviderActivation
    {
        // it should revert with "inactive-lp"
        vm.prank(roles.firstWrongAddress);
        vm.expectRevert("LP not active");
        pool.positionLPInfo(lps[0]);
    }

    modifier whenUserMintTokens() {
        vm.prank(roles.maintainer);
        pool.registerLP(lps[0]);

        for (uint8 i = 0; i < lps.length ; ++i) {
            deal(collateralAddress, lps[i], 100 ether);
        }
        vm.prank(lps[0]);
        collateralAmount = 20 ether;
        CollateralToken.approve(address(pool), 2 * collateralAmount);
        vm.prank(lps[0]);
        pool.activateLP(collateralAmount, overCollateralization);
        _;
    }

    function test_WhenUserMintTokens() external whenTheProtocolWantsToCreateAPool whenUserMintTokens {
        // it should mint synthetic tokens correctly
        // it should validate all LPs gt minCollateralRatio after mint
        ISynthereumMultiLpLiquidityPool.MintParams memory mintParams = ISynthereumMultiLpLiquidityPool.MintParams({minNumTokens : 0.6 ether, collateralAmount : 1 ether, expiration : block.timestamp, recipient : roles.firstWrongAddress});
        vm.startPrank(roles.firstWrongAddress);
        deal(collateralAddress, roles.firstWrongAddress, 100 ether);
        CollateralToken.approve(address(pool), 1 ether);
        pool.mint(mintParams);
        vm.stopPrank();
    }

    function test_GivenMintTransactionExpired() external whenTheProtocolWantsToCreateAPool whenUserMintTokens {
        // it should revert with "expired"
    }

    function test_GivenZeroCollateralSent() external whenTheProtocolWantsToCreateAPool whenUserMintTokens {
        // it should revert with "zero-collateral"
    }

    function test_GivenTokensReceivedLtMinExpected() external whenTheProtocolWantsToCreateAPool whenUserMintTokens {
        // it should revert with "slippage"
    }

    modifier whenUserRedeemTokens() {
        _;
    }

    function test_WhenUserRedeemTokens() external whenTheProtocolWantsToCreateAPool whenUserRedeemTokens {
        // it should redeem tokens correctly
        // it should fully redeem user balance
        // it should validate LPs' collateralization after redeem
    }

    function test_GivenRedeemTransactionExpired() external whenTheProtocolWantsToCreateAPool whenUserRedeemTokens {
        // it should revert with "expired"
    }

    function test_GivenZeroTokensSent() external whenTheProtocolWantsToCreateAPool whenUserRedeemTokens {
        // it should revert with "zero-amount"
    }

    function test_GivenAmountExceedsPoolBalance() external whenTheProtocolWantsToCreateAPool whenUserRedeemTokens {
        // it should revert with "insufficient-liquidity"
    }

    modifier whenLPAddsLiquidity() {
        _;
    }

    function test_WhenLPAddsLiquidity() external whenTheProtocolWantsToCreateAPool whenLPAddsLiquidity {
        // it should allow active LP to add liquidity
    }

    function test_GivenLPIsInactive() external whenTheProtocolWantsToCreateAPool whenLPAddsLiquidity {
        // it should revert with "not-active"
    }

    function test_GivenNoCollateralSent() external whenTheProtocolWantsToCreateAPool whenLPAddsLiquidity {
        // it should revert with "zero-collateral"
    }

    modifier whenLPRemovesLiquidity() {
        _;
    }

    function test_WhenLPRemovesLiquidity() external whenTheProtocolWantsToCreateAPool whenLPRemovesLiquidity {
        // it should allow LP to remove liquidity
    }

    function test_GivenLPIsNotActive() external whenTheProtocolWantsToCreateAPool whenLPRemovesLiquidity {
        // it should revert with "not-active"
    }

    function test_GivenNoLiquidityToWithdraw() external whenTheProtocolWantsToCreateAPool whenLPRemovesLiquidity {
        // it should revert with "nothing-to-withdraw"
    }

    function test_GivenWithdrawalExceedsDeposit() external whenTheProtocolWantsToCreateAPool whenLPRemovesLiquidity {
        // it should revert with "exceeds-balance"
    }

    function test_GivenPost_withdrawCollateralLtMin()
        external
        whenTheProtocolWantsToCreateAPool
        whenLPRemovesLiquidity
    {
        // it should revert with "below-min-collateral"
    }

    modifier whenSettingOvercollateralization() {
        _;
    }

    function test_WhenSettingOvercollateralization()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should allow LP to set overcollateralization
    }

    function test_RevertGiven_LPIsNotActivated()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should revert
    }

    function test_RevertGiven_NewOCLtProtocolRequirement()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should revert
    }

    function test_RevertGiven_PositionBecomesUndercollateralized()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should revert
    }

    function test_RevertGiven_TryingToRemoveTooMuch()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should revert
    }

    function test_RevertGiven_FinalPositionLtRequiredOC()
        external
        whenTheProtocolWantsToCreateAPool
        whenSettingOvercollateralization
    {
        // it should revert
    }

    modifier whenLiquidation() {
        _;
    }

    function test_WhenLiquidation() external whenTheProtocolWantsToCreateAPool whenLiquidation {
        // it should allow liquidation of undercollateralized LP
        // it should liquidate all LP positions
    }

    function test_RevertGiven_LPIsUnactive() external whenTheProtocolWantsToCreateAPool whenLiquidation {
        // it should revert
    }

    function test_RevertGiven_LPIsStillCollateralized() external whenTheProtocolWantsToCreateAPool whenLiquidation {
        // it should revert
    }

    modifier whenLPProfitsOrLossInterestsAreSplit() {
        _;
    }

    function test_WhenLPProfitsOrLossInterestsAreSplit()
        external
        whenTheProtocolWantsToCreateAPool
        whenLPProfitsOrLossInterestsAreSplit
    {
        // it should split lending interests correctly
        // it should distribute profits among LPs
        // it should distribute losses among LPs
    }

    function test_RevertGiven_LPsAreUndercapitalized()
        external
        whenTheProtocolWantsToCreateAPool
        whenLPProfitsOrLossInterestsAreSplit
    {
        // it should revert
    }

    modifier whenTransferToLendingManager() {
        _;
    }

    function test_WhenTransferToLendingManager()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferToLendingManager
    {
        // it should allow transfer to lending manager
    }

    function test_RevertGiven_Non_managerSender()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferToLendingManager
    {
        // it should revert
    }

    modifier whenTransferPoolParamsAreSetByMaintainer() {
        _;
    }

    function test_WhenTransferPoolParamsAreSetByMaintainer()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should update liquidation reward
        // it should update mint/burn fee
    }

    function test_RevertGiven_Non_maintainerSender()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should revert
    }

    function test_RevertGiven_RewardEquals0()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should revert
    }

    function test_RevertGiven_RewardGt100()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should revert
    }

    function test_RevertGiven_Non_maintainerSetsFee()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should revert
    }

    function test_RevertGiven_FeeGte100()
        external
        whenTheProtocolWantsToCreateAPool
        whenTransferPoolParamsAreSetByMaintainer
    {
        // it should revert
    }

    modifier whenStorageMigration() {
        _;
    }

    function test_WhenStorageMigration() external whenTheProtocolWantsToCreateAPool whenStorageMigration {
        // it should allow storage migration
    }

    function test_RevertGiven_CallerIsNotLendingManager()
        external
        whenTheProtocolWantsToCreateAPool
        whenStorageMigration
    {
        // it should revert
    }

    modifier whenGettingTradingInfoFromMinting() {
        _;
    }

    function test_WhenGettingTradingInfoFromMinting()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromMinting
    {
        // it should return mint quote
    }

    function test_RevertGiven_ZeroCollateralAmount()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromMinting
    {
        // it should revert
    }

    function test_RevertGiven_InsufficientLiquidity()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromMinting
    {
        // it should revert
    }

    modifier whenGettingTradingInfoFromRedeeming() {
        _;
    }

    function test_WhenGettingTradingInfoFromRedeeming()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromRedeeming
    {
        // it should return redeem quote
    }

    function test_RevertGiven_NoTokenAmountPassed()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromRedeeming
    {
        // it should revert
    }

    function test_RevertGiven_MoreTokensThanAvailable()
        external
        whenTheProtocolWantsToCreateAPool
        whenGettingTradingInfoFromRedeeming
    {
        // it should revert
    }

    modifier whenSwitchingToANewLendingModuleProtocol() {
        _;
    }

    function test_WhenSwitchingToANewLendingModuleProtocol()
        external
        whenTheProtocolWantsToCreateAPool
        whenSwitchingToANewLendingModuleProtocol
    {
        // it should switch to bonus-yield module
        // it should switch to fee-based lending module
    }

    function test_RevertGiven_CallerIsNotManager()
        external
        whenTheProtocolWantsToCreateAPool
        whenSwitchingToANewLendingModuleProtocol
    {
        // it should revert
    }

    function test_RevertGiven_TooManyTokensRequested()
        external
        whenTheProtocolWantsToCreateAPool
        whenSwitchingToANewLendingModuleProtocol
    {
        // it should revert
    }

    function test_WhenUsingLendingModuleWithDepositBonus() external whenTheProtocolWantsToCreateAPool {
        // it should allow mint
        // it should allow redeem
        // it should allow add liquidity
        // it should allow remove liquidity
        // it should allow liquidation
    }

    function test_WhenUsingLendingModuleWithDepositFees() external whenTheProtocolWantsToCreateAPool {
        // it should allow mint
        // it should allow redeem
        // it should allow add liquidity
        // it should allow remove liquidity
        // it should allow liquidation
    }

    modifier whenClaimingLendingRewards() {
        _;
    }

    function test_WhenClaimingLendingRewards() external whenTheProtocolWantsToCreateAPool whenClaimingLendingRewards {
        // it should allow claiming rewards
    }

    function test_RevertGiven_CallerIsNotMaintainer()
        external
        whenTheProtocolWantsToCreateAPool
        whenClaimingLendingRewards
    {
        // it should revert
    }

    function test_RevertGiven_InvalidCollateralToken()
        external
        whenTheProtocolWantsToCreateAPool
        whenClaimingLendingRewards
    {
        // it should revert
    }

    function test_RevertGiven_WrongBearingToken()
        external
        whenTheProtocolWantsToCreateAPool
        whenClaimingLendingRewards
    {
        // it should revert
    }

    function test_RevertGiven_CallerNotLendingManager()
        external
        whenTheProtocolWantsToCreateAPool
        whenClaimingLendingRewards
    {
        // it should revert
    }
}
