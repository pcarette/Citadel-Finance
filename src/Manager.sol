// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {ISynthereumManager} from './interfaces/IManager.sol';
import {IAccessControlEnumerable} from '@openzeppelin/contracts/access/IAccessControlEnumerable.sol';
import {IEmergencyShutdown} from './interfaces/IEmergencyShutdown.sol';
import {ISynthereumLendingSwitch} from './pool/common/interfaces/ILendingSwitch.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {IVaultFactory} from './multiLP-vaults/interfaces/IVaultFactory.sol';
import {ITransparentUpgradeableProxy,TransparentUpgradeableProxy} from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract SynthereumManager is
  ISynthereumManager,
  ReentrancyGuard,
  AccessControlEnumerable
{
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyMaintainerOrDeployer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender) ||
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Deployer
        ) ==
        msg.sender,
      'Sender must be the maintainer or the deployer'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumManager contract
   * @param _synthereumFinder Synthereum finder contract
   * @param roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory roles) {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

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
  ) external override onlyMaintainerOrDeployer nonReentrant {
    uint256 rolesCount = roles.length;
    require(rolesCount > 0, 'No roles passed');
    require(
      rolesCount == accounts.length,
      'Number of roles and accounts must be the same'
    );
    require(
      rolesCount == contracts.length,
      'Number of roles and contracts must be the same'
    );
    for (uint256 i; i < rolesCount; i++) {
      // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      IAccessControlEnumerable(contracts[i]).grantRole(roles[i], accounts[i]);
    }
  }

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
  ) external override onlyMaintainerOrDeployer nonReentrant {
    uint256 rolesCount = roles.length;
    require(rolesCount > 0, 'No roles passed');
    require(
      rolesCount == accounts.length,
      'Number of roles and accounts must be the same'
    );
    require(
      rolesCount == contracts.length,
      'Number of roles and contracts must be the same'
    );
    for (uint256 i; i < rolesCount; i++) {
      // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      IAccessControlEnumerable(contracts[i]).revokeRole(roles[i], accounts[i]);
    }
  }

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external override onlyMaintainerOrDeployer nonReentrant {
    uint256 rolesCount = roles.length;
    require(rolesCount > 0, 'No roles passed');
    require(
      rolesCount == contracts.length,
      'Number of roles and contracts must be the same'
    );
    for (uint256 i; i < rolesCount; i++) {
      // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      IAccessControlEnumerable(contracts[i]).renounceRole(
        roles[i],
        address(this)
      );
    }
  }

  /**
   * @notice Allow to call emergency shutdown in a pool or self-minting derivative
   * @param contracts Contracts to shutdown
   */
  function emergencyShutdown(IEmergencyShutdown[] calldata contracts)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    require(contracts.length > 0, 'No Derivative passed');
    for (uint256 i; i < contracts.length; i++) {
      // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      contracts[i].emergencyShutdown();
    }
  }

  /**
   * @notice Set new lending protocol for a list of pool
   * @param lendingIds Name of the new lending modules of the pools
   * @param bearingTokens Tokens of the lending mosule to be used for intersts accrual in the pools
   */
  function switchLendingModule(
    ISynthereumLendingSwitch[] calldata pools,
    string[] calldata lendingIds,
    address[] calldata bearingTokens
  ) external override onlyMaintainer nonReentrant {
    uint256 numberOfPools = pools.length;
    require(numberOfPools > 0, 'No pools');
    require(
      numberOfPools == lendingIds.length,
      'Number of pools and ids must be the same'
    );
    require(
      numberOfPools == bearingTokens.length,
      'Number of pools and bearing tokens must be the same'
    );
    for (uint256 i; i < numberOfPools; i++) {
      // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      pools[i].switchLendingModule(lendingIds[i], bearingTokens[i]);
    }
  }

  /**
   * @notice Upgrades implementation logic for a set of vault (proxies) to the one stored in vault factory
   * @param vaults List of vaults
   * @param params List of encoded params to use for initialisation (leave empty to skip initialisation)
   */
  function upgradePublicVault(address[] memory vaults, bytes[] memory params)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    require(vaults.length == params.length, 'Mismatch');

    IVaultFactory vaultFactory = IVaultFactory(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.VaultFactory
      )
    );
    address vaultImplementation = vaultFactory.vaultImplementation();

    for (uint256 i = 0; i < vaults.length; i++) {
      if (params[i].length == 0) {
        // upgrade to new implementation
        // ! Changed TransparentUpgradeableProxy to ITransparentUpgradeableProxy
        // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
        ITransparentUpgradeableProxy(payable(vaults[i])).upgradeTo(
          vaultImplementation
        );
      } else {
        // upgrade and initialise with data
        // ! Changed TransparentUpgradeableProxy to ITransparentUpgradeableProxy
        // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
        ITransparentUpgradeableProxy(payable(vaults[i])).upgradeToAndCall(
          vaultImplementation,
          vaultFactory.encodeInitialiseCall(params[i])
        );
      }
    }
  }

  /**
   * @notice Upgrades admin address for a set of vault (proxies)
   * @param vaults List of vaults
   * @param admins List of new admins
   */
  function changePublicVaultAdmin(
    address[] memory vaults,
    address[] memory admins
  ) external override onlyMaintainer nonReentrant {
    require(vaults.length == admins.length, 'Mismatch');

    for (uint256 i = 0; i < vaults.length; i++) {
      // update proxy admin
        // ! Changed TransparentUpgradeableProxy to ITransparentUpgradeableProxy
        // wake-disable-next-line reentrancy (false positive, entrypoint is nonReentrant)
      ITransparentUpgradeableProxy(payable(vaults[i])).changeAdmin(admins[i]);
    }
  }

  /**
   * @notice Retrieves address of the proxy implementation contract
   * @return address of implementer
   */
  function getCurrentVaultImplementation(address vaultProxy)
    external
    override
    view
    returns (address)
  {
    return ITransparentUpgradeableProxy(payable(vaultProxy)).implementation();
  }
}
