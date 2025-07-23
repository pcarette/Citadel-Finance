// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumCollateralWhitelist} from "../../src/CollateralWhitelist.sol";

contract DeployCollateralWhitelist is Script {
    // address constant COLLATERAL_ADDRESS = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409; // FDUSD
    address constant COLLATERAL_ADDRESS = 0xcF27439fA231af9931ee40c4f27Bb77B83826F3C; // FDUSD testnet
    
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy collateral whitelist
        SynthereumCollateralWhitelist collateralWhitelist = new SynthereumCollateralWhitelist(
            SynthereumCollateralWhitelist.Roles(admin, admin)
        );
        
        // Add collateral to whitelist
        collateralWhitelist.addToWhitelist(COLLATERAL_ADDRESS);
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("CollateralWhitelist")), address(collateralWhitelist));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "COLLATERALWHITELIST_ADDRESS=", vm.toString(address(collateralWhitelist))
        ));
        vm.writeFile("script/deployments/addresses/collateralWhitelist.txt", addressData);
        
        console.log("CollateralWhitelist deployed at:", address(collateralWhitelist));
    }
}