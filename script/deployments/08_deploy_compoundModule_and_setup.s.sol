// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {LendingManager} from "../../src/lending-module/LendingManager.sol";
import {CompoundModule} from "../../src/lending-module/lending-modules/Compound.sol";
import {ILendingStorageManager} from "../../src/lending-module/interfaces/ILendingStorageManager.sol";

contract DeployCompoundModuleAndSetup is Script {
    string constant LENDING_ID = "Compound";
    
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function getLendingManagerAddress() internal view returns (address) {
        string memory lendingManagerData = vm.readFile("script/deployments/addresses/lendingManager.txt");
        return vm.parseAddress(vm.split(lendingManagerData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy compound module
        CompoundModule compoundModule = new CompoundModule();
        
        // Setup lending module
        LendingManager lendingManager = LendingManager(getLendingManagerAddress());
        
        ILendingStorageManager.LendingInfo memory lendingInfo = ILendingStorageManager.LendingInfo(
            address(compoundModule),
            ""
        );
        
        lendingManager.setLendingModule(LENDING_ID, lendingInfo);
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "COMPOUNDMODULE_ADDRESS=", vm.toString(address(compoundModule))
        ));
        vm.writeFile("script/deployments/addresses/compoundModule.txt", addressData);
        
        console.log("CompoundModule deployed at:", address(compoundModule));
        console.log("CompoundModule registered in LendingManager");
    }
}