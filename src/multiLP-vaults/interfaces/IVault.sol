// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../interfaces/IFinder.sol';
import {IVaultMigration} from './IVaultMigration.sol';

/**
 * @title Provides interface for Public vault
 */
interface IVault is IVaultMigration {
  event Deposit(
    address indexed sender,
    address indexed recipient,
    uint256 netCollateralDeposited,
    uint256 lpTokensOut,
    uint256 rate,
    uint256 discountedRate
  );

  event Withdraw(
    address indexed sender,
    address indexed recipient,
    uint256 lpTokensBurned,
    uint256 netCollateralOut,
    uint256 rate
  );

  event LPActivated(uint256 collateralAmount, uint128 overCollateralization);

  event Donation(address indexed sender, uint256 collateralAmount);

  /**
   * @notice Initialize vault as per OZ Clones pattern
   * @param _lpTokenName name of the LP token representing a share in the vault
   * @param _lpTokenSymbol symbol of the LP token representing a share in the vault
   * @param _pool address of MultiLP pool the vault interacts with
   * @param _overCollateralization over collateral requirement of the vault position in the pool
   * @param _finder The synthereum finder
   */
  function initialize(
    string memory _lpTokenName,
    string memory _lpTokenSymbol,
    address _pool,
    uint128 _overCollateralization,
    ISynthereumFinder _finder
  ) external;

  /**
   * @notice Deposits collateral into the vault
   * @param collateralAmount amount of collateral units
   * @param recipient address receiving the LP token
   * @return lpTokensOut amount of LP tokens received as output
   */
  function deposit(uint256 collateralAmount, address recipient)
    external
    returns (uint256 lpTokensOut);

  /**
   * @notice Withdraw collateral from vault
   * @param lpTokensAmount amount of LP token units
   * @param recipient address receiving the collateral
   * @return collateralOut amount of collateral received
   */
  function withdraw(uint256 lpTokensAmount, address recipient)
    external
    returns (uint256 collateralOut);

  /**
   * @notice Deposits collateral into the vault as a form of donation (no LP token minted)
   * @notice that will be split among existing LPs
   */
  function donate(uint256 collateralAmount) external;

  /**
   * @notice Return current LP vault rate against collateral
   * @return rate Vault rate
   */
  function getRate() external view returns (uint256 rate);

  /**
   * @notice Return current LP vault discounted rate against collateral
   * @return rate Vault rate
   * @return discountedRate Vault discounted rate
   * @return maxCollateralDiscounted max amount of collateral units at discount
   */
  function getDiscountedRate()
    external
    view
    returns (
      uint256 rate,
      uint256 discountedRate,
      uint256 maxCollateralDiscounted
    );

  /**
   * @notice Return the vault version
   * @param version version of the vault
   */
  function getVersion() external view returns (uint256 version);

  /**
   * @notice Return the vault reference pool
   * @param poolAddress address of the pool
   */
  function getPool() external view returns (address poolAddress);

  /**
   * @notice Return the vault collateral token
   * @param collateral collateral token
   */
  function getPoolCollateral() external view returns (address collateral);

  /**
   * @notice Return the vault overcollateralization factor
   * @param overcollateral overcollateralization factor
   */
  function getOvercollateralization()
    external
    view
    returns (uint128 overcollateral);

  /**
   * @notice Return the vault reference pool max spread
   * @param maxSpreadLong max spread for buying
   * @param maxSpreadShort max spread for selling
   */
  function getSpread()
    external
    view
    returns (uint256 maxSpreadLong, uint256 maxSpreadShort);
}
