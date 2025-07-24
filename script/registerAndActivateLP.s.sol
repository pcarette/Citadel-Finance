// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumMultiLpLiquidityPoolWithRewards} from "../src/pool/MultiLpLiquidityPoolWithRewards.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RegisterAndActivateLP is Script {
    // Constants
    uint256 constant FDUSD_AMOUNT = 100 * 1e18; // 100 FDUSD
    uint128 constant OVER_COLLATERALIZATION = 1e18; // 1e18 over-collateralization
    
    // Testnet addresses
    address constant POOL_ADDRESS = 0x1FC13b6A5bdc73Ec6e987c10444f5E016eBc2717;
    address constant FDUSD_ADDRESS = 0xcF27439fA231af9931ee40c4f27Bb77B83826F3C; // FDUSD testnet
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address maintainer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumMultiLpLiquidityPoolWithRewards pool = SynthereumMultiLpLiquidityPoolWithRewards(POOL_ADDRESS);
        IERC20 fdusd = IERC20(FDUSD_ADDRESS);
        
        console.log("Maintainer address:", maintainer);
        console.log("Pool address:", POOL_ADDRESS);
        console.log("FDUSD address:", FDUSD_ADDRESS);
        console.log("FDUSD amount to deposit:", FDUSD_AMOUNT);
        console.log("Over-collateralization:", OVER_COLLATERALIZATION);
        
        // Check FDUSD balance
        uint256 balance = fdusd.balanceOf(maintainer);
        console.log("Current FDUSD balance:", balance);
        
        require(balance >= FDUSD_AMOUNT, "Insufficient FDUSD balance");
        
        // Step 1: Register LP (maintainer registers themselves)
        console.log("Step 1: Registering LP...");
        pool.registerLP(maintainer);
        console.log("LP registered successfully");
        
        // Step 2: Approve FDUSD spending
        console.log("Step 2: Approving FDUSD spending...");
        fdusd.approve(POOL_ADDRESS, FDUSD_AMOUNT);
        console.log("FDUSD approved for spending");
        
        // Step 3: Activate LP
        console.log("Step 3: Activating LP...");
        uint256 collateralDeposited = pool.activateLP(FDUSD_AMOUNT, OVER_COLLATERALIZATION);
        console.log("LP activated successfully");
        console.log("Collateral deposited:", collateralDeposited);
        
        vm.stopBroadcast();
        
        console.log("LP registration and activation completed!");
        console.log("LP Address:", maintainer);
        console.log("Pool Address:", POOL_ADDRESS);
        console.log("Collateral Deposited:", collateralDeposited);
        console.log("Over-collateralization:", OVER_COLLATERALIZATION);
    }
}