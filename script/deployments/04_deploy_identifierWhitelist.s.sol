// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumIdentifierWhitelist} from "../../src/IdentifierWhitelist.sol";

contract DeployIdentifierWhitelist is Script {
    string constant PRICE_IDENTIFIER = "EURUSD";
    
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy identifier whitelist
        SynthereumIdentifierWhitelist identifierWhitelist = new SynthereumIdentifierWhitelist(
            SynthereumIdentifierWhitelist.Roles(admin, admin)
        );
        
        // Add identifier to whitelist
        identifierWhitelist.addToWhitelist(bytes32(bytes(PRICE_IDENTIFIER)));
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("IdentifierWhitelist")), address(identifierWhitelist));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "IDENTIFIERWHITELIST_ADDRESS=", vm.toString(address(identifierWhitelist))
        ));
        vm.writeFile("script/deployments/addresses/identifierWhitelist.txt", addressData);
        
        console.log("IdentifierWhitelist deployed at:", address(identifierWhitelist));
    }
}