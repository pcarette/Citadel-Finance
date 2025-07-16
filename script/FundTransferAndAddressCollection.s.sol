// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "forge-std/Script.sol";

contract FundTransfer is Script {
    
    function run() external {
        address userAccount = vm.envAddress("USER_ACCOUNT");
        
        // Known anvil addresses with large balances
        address[] memory richAddresses = new address[](10);
        richAddresses[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // anvil account 0
        richAddresses[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // anvil account 1
        richAddresses[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // anvil account 2
        richAddresses[3] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // anvil account 3
        richAddresses[4] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // anvil account 4
        richAddresses[5] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc; // anvil account 5
        richAddresses[6] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9; // anvil account 6
        richAddresses[7] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955; // anvil account 7
        richAddresses[8] = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f; // anvil account 8
        richAddresses[9] = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // anvil account 9
        
        console.log("Starting fund transfer to user account:", userAccount);
        console.log("User account initial balance:", userAccount.balance);
        
        // Transfer funds from rich addresses to user account
        for (uint i = 0; i < richAddresses.length; i++) {
            address richAddress = richAddresses[i];
            uint256 balance = richAddress.balance;
            
            if (balance > 1 ether) {
                // Keep 1 ETH in the rich address, transfer the rest
                uint256 transferAmount = balance - 1 ether;
                
                vm.startPrank(richAddress);
                payable(userAccount).transfer(transferAmount);
                vm.stopPrank();
                
                console.log("Transferred", transferAmount, "from", richAddress);
                console.log("Rich address remaining balance:", richAddress.balance);
            }
        }
        
        console.log("User account final balance:", userAccount.balance);
        console.log("Fund transfer completed!");
    }
}