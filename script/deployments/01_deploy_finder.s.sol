// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";

contract DeployFinder is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = new SynthereumFinder(
            SynthereumFinder.Roles(admin, admin)
        );
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "FINDER_ADDRESS=", vm.toString(address(finder))
        ));
        vm.writeFile("script/deployments/addresses/finder.txt", addressData);
        
        console.log("Finder deployed at:", address(finder));
    }
}