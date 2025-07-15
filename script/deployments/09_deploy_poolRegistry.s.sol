// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumPoolRegistry} from "../../src/registries/PoolRegistry.sol";

contract DeployPoolRegistry is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy pool registry
        SynthereumPoolRegistry poolRegistry = new SynthereumPoolRegistry(finder);
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("PoolRegistry")), address(poolRegistry));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "POOLREGISTRY_ADDRESS=", vm.toString(address(poolRegistry))
        ));
        vm.writeFile("script/deployments/addresses/poolRegistry.txt", addressData);
        
        console.log("PoolRegistry deployed at:", address(poolRegistry));
    }
}