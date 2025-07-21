# Claude AI Assistant Configuration

This document contains configuration and context information for Claude AI to work effectively with the Citadel Finance protocol codebase.

## Project Overview

**Citadel Finance** is a synthetic stablecoin protocol built on the Jarvis Protocol foundation, enabling the creation of synthetic EUR and other stablecoins through a dual-actor liquidity pool system.

### Key Components

- **Synthetic Stablecoin Protocol**: Creates synthetic EUR from USD stablecoins
- **Multi-LP Liquidity Pools**: Shared liquidity system with two user types
- **Foundry/Solidity**: Smart contracts development framework
- **Docusaurus Documentation**: Technical documentation site with custom theming

## Architecture

### Smart Contracts (Foundry/Solidity)
- **Location**: `/src/` directory
- **Key Contracts**:
  - `MultiLpLiquidityPool.sol` - Core liquidity pool functionality
  - `Finder.sol` - Registry for protocol components
  - `Manager.sol` - Access control and governance
  - `PriceFeed.sol` - Oracle integration (Chainlink)
  - Various factories and registries

### Documentation Site
- **Location**: `/docs/` directory
- **Framework**: Docusaurus v3 with TypeScript
- **Theme**: Custom gradient theme matching WebGL aesthetic
- **Key Pages**: Minter guide, Liquidity Provider guide

## User Types

### 1. Minters (Regular Users)
- Deposit USD stablecoins (FDUSD, USDC, etc.)
- Receive synthetic EUR at current exchange rate
- Pay minting fees (~0.2%)
- Can close positions anytime

### 2. Liquidity Providers (LPs/Shorters)
- Provide liquidity to back synthetic positions
- Earn fees from minting/burning operations
- Earn yield from deployed capital in lending protocols
- Take opposite side of minters' positions

## Development Commands

### Smart Contracts
```bash
# Compile contracts
forge build

# Run tests
forge test

# Deploy (example)
forge script script/deployments/01_deploy_finder.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Documentation
```bash
# Start development server
cd docs && npm start

# Build for production
cd docs && npm run build

# Serve built site
cd docs && npm run serve
```

## Coding Standards

### Solidity
- Follow existing contract patterns and naming conventions
- Use OpenZeppelin libraries where possible
- Maintain security best practices
- Document complex functions with NatSpec

### Documentation
- Write clear, beginner-friendly explanations
- Use examples with realistic numbers
- Maintain consistent Citadel Finance branding
- Follow established file structure

## Key Acknowledgments

This protocol is built on the Jarvis Protocol foundation. Always acknowledge their pioneering work when making significant changes or additions.

## Testing Strategy

- Unit tests for individual contract functions
- Integration tests for cross-contract interactions
- Documentation should include practical examples
- Test mobile responsiveness for docs site

## Deployment Notes

- Use deterministic deployment addresses where possible
- Maintain deployment scripts in `/script/deployments/`
- Document all deployment parameters
- Test on testnets before mainnet deployment

## Support Commands

When working with this codebase, prefer these approaches:

### File Operations
- Use `Read` tool for examining contracts
- Use `Glob` tool for finding files by pattern
- Use `Grep` tool for searching code content

### Development
- Run `forge build` and `forge test` to verify contract changes
- Run `cd docs && npm start` to preview documentation changes
- Check git status before committing changes

## Common Patterns

### Contract Deployment
1. Create deployment script in `/script/deployments/`
2. Test on local fork first
3. Deploy to testnet
4. Deploy to mainnet with verified contracts

### Documentation Updates
1. Update relevant `.md` files in `/docs/docs/`
2. Test locally with `npm start`
3. Commit changes with descriptive messages
4. Build and deploy documentation site

## Security Considerations

- All contracts handle user funds - security is paramount
- Use established patterns from OpenZeppelin and Jarvis Protocol
- Implement proper access controls
- Consider economic attack vectors (oracle manipulation, front-running, etc.)
- Test edge cases thoroughly

---

*This configuration helps Claude AI understand the project structure and provide relevant assistance for Citadel Finance development.*