// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumDeployer} from "../../src/Deployer.sol";

contract DeployDeployer is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy deployer
        SynthereumDeployer deployer = new SynthereumDeployer(
            finder,
            SynthereumDeployer.Roles(admin, admin)
        );
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("Deployer")), address(deployer));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "DEPLOYER_ADDRESS=", vm.toString(address(deployer))
        ));
        vm.writeFile("script/deployments/addresses/deployer.txt", addressData);
        
        console.log("Deployer deployed at:", address(deployer));
    }
}