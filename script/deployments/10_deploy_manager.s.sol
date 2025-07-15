// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumManager} from "../../src/Manager.sol";

contract DeployManager is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy manager
        SynthereumManager manager = new SynthereumManager(
            finder,
            SynthereumManager.Roles(admin, admin)
        );
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("Manager")), address(manager));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "MANAGER_ADDRESS=", vm.toString(address(manager))
        ));
        vm.writeFile("script/deployments/addresses/manager.txt", addressData);
        
        console.log("Manager deployed at:", address(manager));
    }
}