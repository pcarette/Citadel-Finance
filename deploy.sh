#!/bin/bash


# TODO:Ne pas utiliser en prod la ligne suivante
#rm -rf script/deployments/addresses/*


# Deployment script for Jarvis Protocol
# This script deploys all contracts in the correct order

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if environment variables are set
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ Error: Please set RPC_URL and PRIVATE_KEY environment variables${NC}"
    echo "Example:"
    echo "export RPC_URL=\"https://bsc-dataseed.binance.org/\""
    echo "export PRIVATE_KEY=\"your-private-key\""
    exit 1
fi

echo -e "${BLUE}🚀 Starting Jarvis Protocol Deployment${NC}"
echo -e "${YELLOW}RPC URL: $RPC_URL${NC}"
echo -e "${YELLOW}Deploying to: $(cast chain-id --rpc-url $RPC_URL)${NC}"
echo ""

# Array of deployment scripts in order (based on test constructor sequence)
SCRIPTS=(
    "01_deploy_finder.s.sol:DeployFinder"
    "02_deploy_priceFeed_and_chainlink.s.sol:DeployPriceFeedAndChainlink"
    "03_deploy_collateralWhitelist.s.sol:DeployCollateralWhitelist"
    "04_deploy_identifierWhitelist.s.sol:DeployIdentifierWhitelist"
    "05_deploy_tokenFactory.s.sol:DeployTokenFactory"
    "06_deploy_lendingStorageManager.s.sol:DeployLendingStorageManager"
    "07_deploy_lendingManager.s.sol:DeployLendingManager"
    "08_deploy_compoundModule_and_setup.s.sol:DeployCompoundModuleAndSetup"
    "09_deploy_poolRegistry.s.sol:DeployPoolRegistry"
    "10_deploy_manager.s.sol:DeployManager"
    "11_deploy_trustedForwarder.s.sol:DeployTrustedForwarder"
    "12_deploy_factoryVersioning.s.sol:DeployFactoryVersioning"
    "13_deploy_poolFactory.s.sol:DeployPoolFactory"
    "14_deploy_deployer.s.sol:DeployDeployer"
    "15_deploy_pool.s.sol:DeployPool"
)

# Function to deploy a single script
deploy_script() {
    local script=$1
    local script_name=$(echo $script | cut -d':' -f1)
    local contract_name=$(echo $script | cut -d':' -f2)
    
    echo -e "${BLUE}📦 Deploying: $contract_name${NC}"
    echo -e "${YELLOW}   Script: $script_name${NC}"
    
    # Run the forge script command
    if forge script script/deployments/$script --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast; then
        echo -e "${GREEN}✅ Successfully deployed: $contract_name${NC}"
        echo ""
    else
        echo -e "${RED}❌ Failed to deploy: $contract_name${NC}"
        echo -e "${RED}   Script: $script_name${NC}"
        echo ""
        
        # Ask user if they want to continue
        echo -e "${YELLOW}Press Enter to continue with next deployment or Ctrl+C to stop...${NC}"
        read -r
        echo ""
    fi
}

# Create addresses directory if it doesn't exist
mkdir -p script/deployments/addresses

# Start deployment timer
start_time=$(date +%s)

echo -e "${BLUE}Starting deployment of ${#SCRIPTS[@]} contracts...${NC}"
echo ""

# Deploy each script in sequence
for i in "${!SCRIPTS[@]}"; do
    script_num=$((i + 1))
    total_scripts=${#SCRIPTS[@]}
    
    echo -e "${BLUE}[${script_num}/${total_scripts}] ======================================${NC}"
    deploy_script "${SCRIPTS[$i]}"
    
    # Small delay between deployments
    sleep 2
done

# Calculate deployment time
end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

echo -e "${GREEN}🎉 ======================================${NC}"
echo -e "${GREEN}🎉 All contracts deployed successfully!${NC}"
echo -e "${GREEN}🎉 ======================================${NC}"
echo -e "${YELLOW}⏱️  Total deployment time: ${minutes}m ${seconds}s${NC}"
echo ""

# Display deployed addresses
echo -e "${BLUE}📋 Deployed Contract Addresses:${NC}"
echo "=================================="

if [ -d "script/deployments/addresses" ]; then
    for file in script/deployments/addresses/*.txt; do
        if [ -f "$file" ]; then
            echo -e "${YELLOW}$(basename "$file" .txt):${NC}"
            cat "$file"
            echo ""
        fi
    done
else
    echo -e "${RED}No addresses directory found${NC}"
fi

echo -e "${GREEN}🚀 Deployment completed successfully!${NC}"
echo -e "${YELLOW}📁 Address files saved in: script/deployments/addresses/${NC}"

# Run fund transfer and address collection
#echo -e "${BLUE}💰 Running fund transfer and address collection...${NC}"
#forge script script/FundTransferAndAddressCollection.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

