// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumFactoryVersioning} from "../../src/FactoryVersioning.sol";
import {SynthereumMultiLpLiquidityPool} from "../../src/pool/MultiLpLiquidityPool.sol";
import {SynthereumMultiLpLiquidityPoolFactory} from "../../src/pool/MultiLpLiquidityPoolFactory.sol";

contract DeployPoolFactory is Script {
    uint8 constant POOL_VERSION = 1;
    
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function getFactoryVersioningAddress() internal view returns (address) {
        string memory factoryVersioningData = vm.readFile("script/deployments/addresses/factoryVersioning.txt");
        return vm.parseAddress(vm.split(factoryVersioningData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy pool implementation
        SynthereumMultiLpLiquidityPool poolImplementation = new SynthereumMultiLpLiquidityPool();
        
        // Deploy pool factory
        SynthereumMultiLpLiquidityPoolFactory poolFactory = new SynthereumMultiLpLiquidityPoolFactory(
            address(finder),
            address(poolImplementation)
        );
        
        // Register the pool factory in FactoryVersioning
        SynthereumFactoryVersioning factoryVersioning = SynthereumFactoryVersioning(getFactoryVersioningAddress());
        factoryVersioning.setFactory(
            bytes32(bytes("PoolFactory")),
            POOL_VERSION,
            address(poolFactory)
        );
        
        vm.stopBroadcast();
        
        // Write deployed addresses to files
        string memory poolImplData = string(abi.encodePacked(
            "POOLIMPLEMENTATION_ADDRESS=", vm.toString(address(poolImplementation))
        ));
        vm.writeFile("script/deployments/addresses/poolImplementation.txt", poolImplData);
        
        string memory poolFactoryData = string(abi.encodePacked(
            "POOLFACTORY_ADDRESS=", vm.toString(address(poolFactory))
        ));
        vm.writeFile("script/deployments/addresses/poolFactory.txt", poolFactoryData);
        
        console.log("PoolImplementation deployed at:", address(poolImplementation));
        console.log("PoolFactory deployed at:", address(poolFactory));
        console.log("PoolFactory registered in FactoryVersioning");
    }
}