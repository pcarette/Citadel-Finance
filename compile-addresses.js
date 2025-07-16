#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const addressesDir = 'script/deployments/addresses';
const outputFile = 'deployed_addresses.json';

const contractNames = [
    'finder',
    'deployer', 
    'priceFeed',
    'chainlinkPriceFeed',
    'collateralWhitelist',
    'identifierWhitelist',
    'tokenFactory',
    'lendingStorageManager',
    'lendingManager',
    'compoundModule',
    'poolRegistry',
    'manager',
    'trustedForwarder',
    'factoryVersioning',
    'poolFactory',
    'pool',
    'poolImplementation'
];

function extractAddressFromFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const match = content.match(/0x[a-fA-F0-9]{40}/);
        return match ? match[0] : null;
    } catch (error) {
        return null;
    }
}

function compileAddresses() {
    const deployedAddresses = {};
    
    console.log('Compiling deployed addresses...');
    
    for (const contractName of contractNames) {
        const filePath = path.join(addressesDir, `${contractName}.txt`);
        const address = extractAddressFromFile(filePath);
        
        if (address) {
            deployedAddresses[contractName] = address;
            console.log(`✓ ${contractName}: ${address}`);
        } else {
            console.log(`✗ ${contractName}: not found or invalid`);
        }
    }
    
    const output = {
        deployedAddresses,
        network: 'anvil-fork',
        timestamp: new Date().toISOString(),
        compiledAt: Math.floor(Date.now() / 1000)
    };
    
    fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));
    
    console.log(`\n📄 Compiled ${Object.keys(deployedAddresses).length} addresses to ${outputFile}`);
    
    return output;
}

if (require.main === module) {
    compileAddresses();
}

module.exports = { compileAddresses };