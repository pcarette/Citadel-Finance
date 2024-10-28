// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ILendingStorageManager {
  struct PoolStorage {
    bytes32 lendingModuleId; // hash of the lending module id associated with the LendingInfo the pool currently is using
    uint256 collateralDeposited; // amount of collateral currently deposited in the MoneyMarket
    uint256 unclaimedDaoJRT; // amount of interest to be claimed to buyback JRT
    uint256 unclaimedDaoCommission; // amount of interest to be claimed as commission (in collateral)
    address collateral; // collateral address of the pool
    uint64 jrtBuybackShare; // share of dao interest used to buyback JRT
    address interestBearingToken; // interest token address of the pool
    uint64 daoInterestShare; // share of total interest generated by the pool directed to the DAO
  }

  struct PoolLendingStorage {
    address collateralToken; // address of the collateral token of a pool
    address interestToken; // address of interest token of a pool
  }

  struct LendingInfo {
    address lendingModule; // address of the ILendingModule interface implementer
    bytes args; // encoded args the ILendingModule implementer might need
  }

  /**
   * @notice sets a ILendingModule implementer info
   * @param _id string identifying a specific ILendingModule implementer
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param _pool pool address to set shares on
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address _pool,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice store data for lending manager associated to a pool
   * @param _lendingID string identifying the associated ILendingModule implementer
   * @param _pool pool address to set info
   * @param _collateral collateral address of the pool
   * @param _interestBearingToken address of the interest token in use
   * @param _daoInterestShare share of total interest generated assigned to the dao
   * @param _jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setPoolStorage(
    string calldata _lendingID,
    address _pool,
    address _collateral,
    address _interestBearingToken,
    uint64 _daoInterestShare,
    uint64 _jrtBuybackShare
  ) external;

  /**
   * @notice assign oldPool storage information and state to newPool address and deletes oldPool storage slot
   * @dev is used when a pool is redeployed and the liquidity transferred over
   * @param _oldPool address of old pool to migrate storage from
   * @param _newPool address of the new pool receiving state of oldPool
   * @param _newCollateralDeposited Amount of collateral deposited in the new pool after the migration
   */
  function migratePoolStorage(
    address _oldPool,
    address _newPool,
    uint256 _newCollateralDeposited
  ) external;

  /**
   * @notice sets new lending info on a pool
   * @dev used when migrating liquidity from one lending module (and money market), to a new one
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _pool address of the pool whose associated lending module is being migrated
   * @param _newInterestToken address of the interest token of the new Lending Module (can be set blank)
   * @return poolData with the updated state
   * @return lendingInfo of the new lending module
   */
  function migrateLendingModule(
    string calldata _newLendingID,
    address _pool,
    address _newInterestToken
  ) external returns (PoolStorage memory, LendingInfo memory);

  /**
   * @notice updates storage of a pool
   * @dev should be callable only by LendingManager after state-changing operations
   * @param _pool address of the pool to update values
   * @param _collateralDeposited updated amount of collateral deposited
   * @param _daoJRT updated amount of unclaimed interest for JRT buyback
   * @param _daoInterest updated amount of unclaimed interest as dao commission
   */
  function updateValues(
    address _pool,
    uint256 _collateralDeposited,
    uint256 _daoJRT,
    uint256 _daoInterest
  ) external;

  /**
   * @notice Returns info about a supported lending module
   * @param _id Name of the module
   * @return lendingInfo Address and bytes associated to the lending mdodule
   */
  function getLendingModule(string calldata _id)
    external
    view
    returns (LendingInfo memory lendingInfo);

  /**
   * @notice reads PoolStorage of a pool
   * @param _pool address of the pool to read storage
   * @return poolData pool struct info
   */
  function getPoolStorage(address _pool)
    external
    view
    returns (PoolStorage memory poolData);

  /**
   * @notice reads PoolStorage and LendingInfo of a pool
   * @param _pool address of the pool to read storage
   * @return poolData pool struct info
   * @return lendingInfo information of the lending module associated with the pool
   */
  function getPoolData(address _pool)
    external
    view
    returns (PoolStorage memory poolData, LendingInfo memory lendingInfo);

  /**
   * @notice reads lendingStorage and LendingInfo of a pool
   * @param _pool address of the pool to read storage
   * @return lendingStorage information of the addresses of collateral and intrestToken
   * @return lendingInfo information of the lending module associated with the pool
   */
  function getLendingData(address _pool)
    external
    view
    returns (
      PoolLendingStorage memory lendingStorage,
      LendingInfo memory lendingInfo
    );

  /**
   * @notice Return the list containing every swap module supported
   * @return List of swap modules
   */
  function getSwapModules() external view returns (address[] memory);

  /**
   * @notice reads the JRT Buyback module associated to a collateral
   * @param _collateral address of the collateral to retrieve module
   * @return swapModule address of interface implementer of the IJRTSwapModule
   */
  function getCollateralSwapModule(address _collateral)
    external
    view
    returns (address swapModule);

  /**
   * @notice reads the interest beaaring token address associated to a pool
   * @param _pool address of the pool to retrieve interest token
   * @return interestTokenAddr address of the interest token
   */
  function getInterestBearingToken(address _pool)
    external
    view
    returns (address interestTokenAddr);

  /**
   * @notice reads the shares used for splitting interests between pool, dao and buyback
   * @param _pool address of the pool to retrieve interest token
   * @return jrtBuybackShare Percentage of interests claimable by th DAO
   * @return daoInterestShare Percentage of interests used for the buyback
   */
  function getShares(address _pool)
    external
    view
    returns (uint256 jrtBuybackShare, uint256 daoInterestShare);

  /**
   * @notice reads the last collateral amount deposited in the pool
   * @param _pool address of the pool to retrieve collateral amount
   * @return collateralAmount Amount of collateral deposited in the pool
   */
  function getCollateralDeposited(address _pool)
    external
    view
    returns (uint256 collateralAmount);
}