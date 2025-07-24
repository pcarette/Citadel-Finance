#!/bin/bash

# Setup LP Script
# Registers maintainer as LP and activates with 100 FDUSD and 1e18 over-collateralization

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
    echo "export RPC_URL=\"https://data-seed-prebsc-1-s1.binance.org:8545/\""
    echo "export PRIVATE_KEY=\"your-private-key\""
    exit 1
fi

echo -e "${BLUE}🚀 Setting up LP (Liquidity Provider)${NC}"
echo -e "${YELLOW}RPC URL: $RPC_URL${NC}"
echo -e "${YELLOW}Network: $(cast chain-id --rpc-url $RPC_URL)${NC}"
echo ""

echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "${YELLOW}  • Pool: 0x1FC13b6A5bdc73Ec6e987c10444f5E016eBc2717${NC}"
echo -e "${YELLOW}  • FDUSD: 0xcF27439fA231af9931ee40c4f27Bb77B83826F3C${NC}"
echo -e "${YELLOW}  • Amount: 100 FDUSD${NC}"
echo -e "${YELLOW}  • Over-collateralization: 1e18${NC}"
echo ""

# Run the forge script
echo -e "${BLUE}🔄 Executing LP setup...${NC}"
if forge script script/registerAndActivateLP.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv; then
    echo ""
    echo -e "${GREEN}🎉 ======================================${NC}"
    echo -e "${GREEN}🎉 LP Setup Completed Successfully!${NC}"
    echo -e "${GREEN}🎉 ======================================${NC}"
    echo ""
    echo -e "${YELLOW}✅ Maintainer is now registered and active as LP${NC}"
    echo -e "${YELLOW}✅ 100 FDUSD deposited as collateral${NC}"
    echo -e "${YELLOW}✅ Over-collateralization set to 1e18${NC}"
else
    echo ""
    echo -e "${RED}❌ ======================================${NC}"
    echo -e "${RED}❌ LP Setup Failed!${NC}"
    echo -e "${RED}❌ ======================================${NC}"
    echo ""
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "${YELLOW}  • You have enough FDUSD balance (100+ FDUSD)${NC}"
    echo -e "${YELLOW}  • The maintainer role is correctly set${NC}"
    echo -e "${YELLOW}  • Network connectivity${NC}"
    exit 1
fi