// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";
import {SynthereumFinder} from "../../src/Finder.sol";
import {SynthereumPriceFeed} from "../../src/oracle/PriceFeed.sol";
import {SynthereumChainlinkPriceFeed} from "../../src/oracle/implementations/ChainlinkPriceFeed.sol";
import {SynthereumPriceFeedImplementation} from "../../src/oracle/implementations/PriceFeedImplementation.sol";
import {StandardAccessControlEnumerable} from "../../src/roles/StandardAccessControlEnumerable.sol";

import { PythAggregatorV3 } from "@pythnetwork/pyth-sdk-solidity/PythAggregatorV3.sol";

contract DeployPriceFeedAndChainlink is Script {
    string constant PRICE_IDENTIFIER = "EURUSD";
    uint64 constant MAX_SPREAD = 0.001 ether;
    
    //We need to deploy pyth price feed on testnet instead of connect to chainlink one: 
    //address constant AGGREGATOR = 0x0bf79F617988C472DcA68ff41eFe1338955b9A80; // Chainlink BSC data feed address
    // Get the address for your ecosystem from:
    // https://docs.pyth.network/price-feeds/contract-addresses/evm
    address pythPriceFeedsContract = 0x5744Cbf430D99456a0A8771208b674F27f8EF0Fb; // BSC Testnet one

    
    function getFinderAddress() internal view returns (address) {
        string memory finderData = vm.readFile("script/deployments/addresses/finder.txt");
        return vm.parseAddress(vm.split(finderData, "=")[1]);
    }
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        SynthereumFinder finder = SynthereumFinder(getFinderAddress());
        
        // Deploy price feed
        SynthereumPriceFeed priceFeed = new SynthereumPriceFeed(
            finder,
            StandardAccessControlEnumerable.Roles(admin, admin)
        );
        
        // Deploy chainlink price feed
        SynthereumChainlinkPriceFeed chainlinkPriceFeed = new SynthereumChainlinkPriceFeed(
            finder,
            StandardAccessControlEnumerable.Roles(admin, admin)
        );
        
        // Register price feed in finder
        finder.changeImplementationAddress(bytes32(bytes("PriceFeed")), address(priceFeed));
        
        // Setup price feed oracle
        priceFeed.addOracle("chainlink", address(chainlinkPriceFeed));

        //Deploy IPyth replacor of chainlink aggregator :
        PythAggregatorV3 aggregatorInstance = new PythAggregatorV3(pythPriceFeedsContract, 0xa995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b);

        
        // Setup chainlink price feed pair
        chainlinkPriceFeed.setPair(
            PRICE_IDENTIFIER,
            SynthereumPriceFeedImplementation.Type(1),
            address(aggregatorInstance), //AGGREGATOR,
            0,
            "",
            MAX_SPREAD
        );
        
        // Setup price feed pair
        string[] memory emptyArray;
        priceFeed.setPair(
            PRICE_IDENTIFIER,
            SynthereumPriceFeed.Type(1),
            "chainlink",
            emptyArray
        );
        
        vm.stopBroadcast();
        
        // Write deployed addresses to files
        string memory priceFeedData = string(abi.encodePacked(
            "PRICEFEED_ADDRESS=", vm.toString(address(priceFeed))
        ));
        vm.writeFile("script/deployments/addresses/priceFeed.txt", priceFeedData);
        
        string memory chainlinkData = string(abi.encodePacked(
            "CHAINLINKPRICEFEED_ADDRESS=", vm.toString(address(chainlinkPriceFeed))
        ));
        vm.writeFile("script/deployments/addresses/chainlinkPriceFeed.txt", chainlinkData);
        
        string memory pythAggregatorData = string(abi.encodePacked(
            "PYTH_AGGREGATOR_ADDRESS=", vm.toString(address(aggregatorInstance))
        ));
        vm.writeFile("script/deployments/addresses/pythAggregator.txt", pythAggregatorData);
        
        console.log("PriceFeed deployed at:", address(priceFeed));
        console.log("ChainlinkPriceFeed deployed at:", address(chainlinkPriceFeed));
        console.log("Pyth Aggregator deployed at:", address(aggregatorInstance));
    }
}