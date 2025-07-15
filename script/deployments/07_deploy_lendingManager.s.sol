// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {LendingManager} from "../../src/lending-module/LendingManager.sol";
import {ILendingManager} from "../../src/lending-module/interfaces/ILendingManager.sol";

contract DeployLendingManager is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy lending manager
        LendingManager lendingManager = new LendingManager(
            finder,
            ILendingManager.Roles(admin, admin)
        );
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("LendingManager")), address(lendingManager));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "LENDINGMANAGER_ADDRESS=", vm.toString(address(lendingManager))
        ));
        vm.writeFile("script/deployments/addresses/lendingManager.txt", addressData);
        
        console.log("LendingManager deployed at:", address(lendingManager));
    }
}