// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {LendingStorageManager} from "../../src/lending-module/LendingStorageManager.sol";

contract DeployLendingStorageManager is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy lending storage manager
        LendingStorageManager lendingStorageManager = new LendingStorageManager(finder);
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("LendingStorageManager")), address(lendingStorageManager));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "LENDINGSTORAGEMANAGER_ADDRESS=", vm.toString(address(lendingStorageManager))
        ));
        vm.writeFile("script/deployments/addresses/lendingStorageManager.txt", addressData);
        
        console.log("LendingStorageManager deployed at:", address(lendingStorageManager));
    }
}