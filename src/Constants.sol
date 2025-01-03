// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant VaultRegistry = 'VaultRegistry';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant DebtTokenFactory = 'DebtTokenFactory';
  bytes32 public constant VaultFactory = 'VaultFactory';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant CrossChainBridge = 'CrossChainBridge';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}
