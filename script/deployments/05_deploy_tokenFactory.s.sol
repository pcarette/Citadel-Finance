// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumSyntheticTokenPermitFactory} from "../../src/tokens/factories/SyntheticTokenPermitFactory.sol";

contract DeployTokenFactory is Script {
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy token factory
        SynthereumSyntheticTokenPermitFactory tokenFactory = new SynthereumSyntheticTokenPermitFactory(
            address(finder)
        );
        
        // Register in finder
        finder.changeImplementationAddress(bytes32(bytes("TokenFactory")), address(tokenFactory));
        
        vm.stopBroadcast();
        
        // Write deployed address to file
        string memory addressData = string(abi.encodePacked(
            "TOKENFACTORY_ADDRESS=", vm.toString(address(tokenFactory))
        ));
        vm.writeFile("script/deployments/addresses/tokenFactory.txt", addressData);
        
        console.log("TokenFactory deployed at:", address(tokenFactory));
    }
}