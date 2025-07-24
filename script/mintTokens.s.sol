// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumMultiLpLiquidityPoolWithRewards} from "../src/pool/MultiLpLiquidityPoolWithRewards.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISynthereumMultiLpLiquidityPool} from "../src/pool/interfaces/IMultiLpLiquidityPool.sol";

contract MintTokens is Script {
    // Constants
    uint256 constant FDUSD_AMOUNT = 20 * 1e18; // 20 FDUSD for minting
    
    // Testnet addresses
    address constant POOL_ADDRESS = 0x1FC13b6A5bdc73Ec6e987c10444f5E016eBc2717;
    address constant FDUSD_ADDRESS = 0xcF27439fA231af9931ee40c4f27Bb77B83826F3C; // FDUSD testnet
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumMultiLpLiquidityPoolWithRewards pool = SynthereumMultiLpLiquidityPoolWithRewards(POOL_ADDRESS);
        IERC20 fdusd = IERC20(FDUSD_ADDRESS);
        
        console.log("Minter address:", minter);
        console.log("Pool address:", POOL_ADDRESS);
        console.log("FDUSD address:", FDUSD_ADDRESS);
        console.log("FDUSD amount to mint with:", FDUSD_AMOUNT);
        
        // Check FDUSD balance
        uint256 balance = fdusd.balanceOf(minter);
        console.log("Current FDUSD balance:", balance);
        
        require(balance >= FDUSD_AMOUNT, "Insufficient FDUSD balance");
        
        // Step 1: Approve FDUSD spending
        console.log("Step 1: Approving FDUSD spending...");
        fdusd.approve(POOL_ADDRESS, FDUSD_AMOUNT);
        console.log("FDUSD approved for spending");
        
        // Step 2: Prepare mint parameters
        ISynthereumMultiLpLiquidityPool.MintParams memory mintParams = ISynthereumMultiLpLiquidityPool.MintParams({
            minNumTokens: 0, // Accept any amount of synthetic tokens
            collateralAmount: FDUSD_AMOUNT,
            expiration: block.timestamp + 300, // 5 minutes from now
            recipient: minter
        });
        
        // Step 3: Mint synthetic tokens (cEUR)
        console.log("Step 2: Minting cEUR tokens...");
        (uint256 synthTokensMinted, uint256 feePaid) = pool.mint(mintParams);
        console.log("Minting completed successfully!");
        console.log("Synthetic tokens minted:", synthTokensMinted);
        console.log("Fee paid:", feePaid);
        
        // Get synthetic token address and check balance
        address synthTokenAddress = address(pool.syntheticToken());
        IERC20 synthToken = IERC20(synthTokenAddress);
        uint256 synthBalance = synthToken.balanceOf(minter);
        
        console.log("Synthetic token address:", synthTokenAddress);
        console.log("Final synthetic token balance:", synthBalance);
        
        vm.stopBroadcast();
        
        console.log("Minting operation completed!");
        console.log("Minter Address:", minter);
        console.log("Pool Address:", POOL_ADDRESS);
        console.log("Collateral Used:", FDUSD_AMOUNT);
        console.log("Synthetic Tokens Minted:", synthTokensMinted);
        console.log("Fee Paid:", feePaid);
    }
}