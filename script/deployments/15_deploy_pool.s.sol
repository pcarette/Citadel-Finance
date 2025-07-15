// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumDeployer} from "../../src/Deployer.sol";
import {StandardAccessControlEnumerable} from "../../src/roles/StandardAccessControlEnumerable.sol";

contract DeployPool is Script {
    // Pool configuration
    address constant COLLATERAL_ADDRESS = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
    string constant PRICE_IDENTIFIER = "EURUSD";
    string constant SYNTHETIC_NAME = "Citadel Euro";
    string constant SYNTHETIC_SYMBOL = "cEUR";
    string constant LENDING_ID = "Compound";
    uint64 constant DAO_INTEREST_SHARE = 0.1 ether;
    uint64 constant JRT_BUYBACK_SHARE = 0.6 ether;
    uint8 constant POOL_VERSION = 1;
    uint128 constant OVER_COLLATERAL_REQUIREMENT = 0.05 ether;
    uint64 constant LIQUIDATION_REWARD = 0.5 ether;
    uint64 constant FEE_PERCENTAGE = 0.002 ether; // 0.2% fee
    address constant DEBT_TOKEN_ADDRESS = 0xC4eF4229FEc74Ccfe17B2bdeF7715fAC740BA0ba; // aave aBnbFdusd debt token
    
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

    function getDeployerAddress() internal view returns (address) {
        string memory deployerData = vm.readFile("script/deployments/addresses/deployer.txt");
        return vm.parseAddress(vm.split(deployerData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumDeployer deployer = SynthereumDeployer(getDeployerAddress());
        
        // Setup pool parameters
        LendingManagerParams memory lendingManagerParams = LendingManagerParams(
            LENDING_ID,
            DEBT_TOKEN_ADDRESS,
            DAO_INTEREST_SHARE,
            JRT_BUYBACK_SHARE
        );

        PoolParams memory poolParams = PoolParams(
            POOL_VERSION,
            COLLATERAL_ADDRESS,
            SYNTHETIC_NAME,
            SYNTHETIC_SYMBOL,
            address(0),
            StandardAccessControlEnumerable.Roles(admin, admin),
            FEE_PERCENTAGE,
            bytes32(bytes(PRICE_IDENTIFIER)),
            OVER_COLLATERAL_REQUIREMENT,
            LIQUIDATION_REWARD,
            lendingManagerParams
        );

        // Deploy the pool
        address poolAddress = address(deployer.deployPool(POOL_VERSION, abi.encode(poolParams)));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory poolData = string(abi.encodePacked(
            "POOL_ADDRESS=", vm.toString(poolAddress)
        ));
        vm.writeFile("script/deployments/addresses/pool.txt", poolData);
        
        console.log("Pool deployed at:", poolAddress);
    }
}