// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumTrustedForwarder} from "../../src/TrustedForwarder.sol";

contract DeployTrustedForwarder is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy trusted forwarder
        SynthereumTrustedForwarder trustedForwarder = new SynthereumTrustedForwarder();
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("TrustedForwarder")), address(trustedForwarder));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "TRUSTEDFORWARDER_ADDRESS=", vm.toString(address(trustedForwarder))
        ));
        vm.writeFile("script/deployments/addresses/trustedForwarder.txt", addressData);
        
        console.log("TrustedForwarder deployed at:", address(trustedForwarder));
    }
}