// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IEmergencyShutdown} from './IEmergencyShutdown.sol';
import {ISynthereumLendingSwitch} from '../pool/common/interfaces/ILendingSwitch.sol';

interface ISynthereumManager {
  /**
   * @notice Allow to add roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which give the grant
   */
  function grantSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to revoke roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which revoke the grant
   */
  function revokeSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external;

  /**
   * @notice Allow to call emergency shutdown in a pool or self-minting derivative
   * @param contracts Contracts to shutdown
   */
  function emergencyShutdown(IEmergencyShutdown[] calldata contracts) external;

  /**
   * @notice Set new lending protocol for a list of pool
   * @param lendingIds Name of the new lending modules of the pools
   * @param bearingTokens Tokens of the lending mosule to be used for intersts accrual in the pools
   */
  function switchLendingModule(
    ISynthereumLendingSwitch[] calldata pools,
    string[] calldata lendingIds,
    address[] calldata bearingTokens
  ) external;

  /**
   * @notice Upgrades implementation logic for a set of vault (proxies) to the one stored in vault factory
   * @param vaults List of vaults
   * @param params List of encoded params to use for initialisation (leave empty to skip initialisation)
   */
  function upgradePublicVault(address[] memory vaults, bytes[] memory params)
    external;

  /**
   * @notice Upgrades admin address for a set of vault (proxies)
   * @param vaults List of vaults
   * @param admins List of new admins
   */
  function changePublicVaultAdmin(
    address[] memory vaults,
    address[] memory admins
  ) external;

  /**
   * @notice Retrieves address of the proxy implementation contract
   * @return address of implementer
   */
  function getCurrentVaultImplementation(address vaultProxy)
    external
    returns (address);
}
