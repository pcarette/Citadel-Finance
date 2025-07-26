// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {console} from "../../lib/forge-std/src/console.sol";
import {FaucetLimiter} from "../../src/FaucetLimiter.sol";

// Interface for the MultiLpLiquidityPool contract to register LPs
interface IMultiLpLiquidityPool {
    function registerLP(address _lp) external;
}

/**
 * @title Deploy Faucet Limiter and Register Vaults as LPs
 * @notice This script:
 * 1. Deploys the FaucetLimiter contract
 * 2. Registers all three vault addresses as LPs in the pool
 */
contract DeployFaucetAndRegisterVaults is Script {
    // From testnet-addresses.json
    address constant POOL_ADDRESS = 0x1FC13b6A5bdc73Ec6e987c10444f5E016eBc2717;
    address constant COLLATERAL_ADDRESS = 0xcF27439fA231af9931ee40c4f27Bb77B83826F3C; // FDUSD
    
    // Vault addresses
    address constant VAULT_1X = 0x5C9E2E892DF72696392738143DD4272464251cA0;
    address constant VAULT_5X = 0xD0118881bc4E6d8b3937495C3343473e4d250041;
    address constant VAULT_20X = 0xbeBCe4030848c8B9a37c8bc5C8Af286B4BbaCe8D;

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Pool address:", POOL_ADDRESS);
        console.log("FDUSD address:", COLLATERAL_ADDRESS);
        
        vm.startBroadcast(deployerPrivateKey);

        // // Step 1: Deploy FaucetLimiter contract
        // console.log("\n=== Deploying FaucetLimiter ===");
        // FaucetLimiter faucetLimiter = new FaucetLimiter(COLLATERAL_ADDRESS);
        // console.log("FaucetLimiter deployed at:", address(faucetLimiter));

        // Step 2: Get pool interface
        IMultiLpLiquidityPool pool = IMultiLpLiquidityPool(POOL_ADDRESS);

        // Step 3: Register 1x Vault as LP
        console.log("\n=== Registering 1x Vault as LP ===");
        console.log("Vault 1x address:", VAULT_1X);
        
        try pool.registerLP(VAULT_1X) {
            console.log("1x Vault registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to register 1x Vault:", reason);
        }

        // Step 4: Register 5x Vault as LP
        console.log("\n=== Registering 5x Vault as LP ===");
        console.log("Vault 5x address:", VAULT_5X);
        
        try pool.registerLP(VAULT_5X) {
            console.log("5x Vault registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to register 5x Vault:", reason);
        }

        // Step 5: Register 20x Vault as LP
        console.log("\n=== Registering 20x Vault as LP ===");
        console.log("Vault 20x address:", VAULT_20X);
        
        try pool.registerLP(VAULT_20X) {
            console.log("20x Vault registered successfully");
        } catch Error(string memory reason) {
            console.log("Failed to register 20x Vault:", reason);
        }

        vm.stopBroadcast();

        // Step 6: Write addresses to file
        // console.log("\n=== Writing addresses to file ===");
        // string memory faucetAddress = vm.toString(address(faucetLimiter));
        
        // vm.writeFile("./script/deployments/addresses/faucetLimiter.txt", faucetAddress);
        vm.writeFile("./script/deployments/addresses/registered_vaults.txt", 
            string(abi.encodePacked(
                "VAULT_1X_REGISTERED=", vm.toString(VAULT_1X), "\n",
                "VAULT_5X_REGISTERED=", vm.toString(VAULT_5X), "\n", 
                "VAULT_20X_REGISTERED=", vm.toString(VAULT_20X), "\n"
            ))
        );
        
        // Step 7: Deployment Summary
        console.log("\n=== Deployment Summary ===");
        // console.log("FaucetLimiter address:", address(faucetLimiter));
        console.log("Registered Vaults in Pool:");
        console.log("  - 1x Vault:", VAULT_1X);
        console.log("  - 5x Vault:", VAULT_5X);
        console.log("  - 20x Vault:", VAULT_20X);
        console.log("Addresses written to:");
        console.log("  - ./script/deployments/addresses/faucetLimiter.txt");
        console.log("  - ./script/deployments/addresses/registered_vaults.txt");
    }
}