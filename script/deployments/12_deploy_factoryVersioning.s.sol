// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumFactoryVersioning} from "../../src/FactoryVersioning.sol";

contract DeployFactoryVersioning is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy factory versioning
        SynthereumFactoryVersioning factoryVersioning = new SynthereumFactoryVersioning(
            SynthereumFactoryVersioning.Roles(admin, admin)
        );
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("FactoryVersioning")), address(factoryVersioning));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "FACTORYVERSIONING_ADDRESS=", vm.toString(address(factoryVersioning))
        ));
        vm.writeFile("script/deployments/addresses/factoryVersioning.txt", addressData);
        
        console.log("FactoryVersioning deployed at:", address(factoryVersioning));
    }
}