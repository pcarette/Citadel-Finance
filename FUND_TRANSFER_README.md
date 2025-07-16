# Fund Transfer and Address Collection Script

This script transfers BNB from pre-funded anvil addresses to your specified user account and generates a JSON file with all deployed contract addresses.

## Setup

1. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set your `USER_ACCOUNT` address where you want to receive the funds:
   ```
   USER_ACCOUNT=0xYourAddressHere
   ```

## Usage

Run the script with forge:

```bash
forge script script/FundTransferAndAddressCollection.s.sol --rpc-url http://localhost:8545 --broadcast
```

Or if you want to use a different RPC URL:

```bash
forge script script/FundTransferAndAddressCollection.s.sol --rpc-url $RPC_URL --broadcast
```

## What the script does

1. **Fund Transfer**: 
   - Identifies 10 pre-funded anvil addresses with large BNB balances
   - Transfers funds from these addresses to your `USER_ACCOUNT`
   - Leaves 1 ETH in each source address to keep them functional

2. **Address Collection**:
   - Reads all deployed contract addresses from the `script/deployments/addresses/` directory
   - Generates a comprehensive JSON file named `deployed_addresses.json`
   - Includes metadata like network type and timestamp

## Output

- **Console**: Shows transfer amounts and final balances
- **File**: `deployed_addresses.json` with all deployed contract addresses

## Pre-funded Addresses Used

The script transfers from these standard anvil test addresses:
- `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (anvil account 0)
- `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (anvil account 1)
- ... and 8 more anvil accounts

## Requirements

- Anvil fork running with pre-funded accounts
- Foundry environment set up
- `.env` file with `USER_ACCOUNT` configured