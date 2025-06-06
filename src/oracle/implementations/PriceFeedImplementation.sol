// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../interfaces/IFinder.sol';
import {ISynthereumPriceFeedImplementation} from './interfaces/IPriceFeedImplementation.sol';
import {SynthereumInterfaces} from '../../Constants.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {StringUtils} from '../../base/utils/StringUtils.sol';
import {StandardAccessControlEnumerable} from '../../roles/StandardAccessControlEnumerable.sol';

/**
 * @title Abstarct contract inherited by the price-feed implementations
 */
abstract contract SynthereumPriceFeedImplementation is
  ISynthereumPriceFeedImplementation,
  StandardAccessControlEnumerable
{
  using PreciseUnitMath for uint256;
  using Address for address;
  using StringUtils for string;

  enum Type {
    UNSUPPORTED,
    NORMAL,
    REVERSE
  }

  struct PairData {
    Type priceType;
    address source;
    uint64 maxSpread;
    uint256 conversionUnit;
    bytes extraData;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------
  ISynthereumFinder public immutable synthereumFinder;
  mapping(bytes32 => PairData) private pairs;

  //----------------------------------------
  // Events
  //----------------------------------------
  event SetPair(
    bytes32 indexed priceIdentifier,
    Type kind,
    address source,
    uint256 conversionUnit,
    bytes extraData,
    uint64 maxSpread
  );

  event RemovePair(bytes32 indexed priceIdentifier);

  //----------------------------------------
  // Modifiers
  //----------------------------------------
  modifier onlyPriceFeed() {
    if (msg.sender != tx.origin) {
      address priceFeed = synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PriceFeed
      );
      require(msg.sender == priceFeed, 'Only price-feed');
    }
    _;
  }

  modifier onlyCall() {
    require(msg.sender == tx.origin, 'Only off-chain call');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumPriceFeedImplementation contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setAdmin(_roles.admin);
    _setMaintainer(_roles.maintainer);
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------
  /**
   * @notice Add support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public virtual onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(priceIdentifierHex != 0x0, 'Null identifier');
    if (_kind == Type.NORMAL || _kind == Type.REVERSE) {
      require(_source.isContract(), 'Source is not a contract');
    } else {
      revert('No type passed');
    }
    require(
      _maxSpread < PreciseUnitMath.PRECISE_UNIT,
      'Spread must be less than 100%'
    );

    pairs[priceIdentifierHex] = PairData(
      _kind,
      _source,
      _maxSpread,
      _conversionUnit,
      _extraData
    );

    emit SetPair(
      priceIdentifierHex,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
  }

  /**
   * @notice Remove support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   */
  function removePair(string calldata _priceId) public virtual onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(
      pairs[priceIdentifierHex].priceType != Type.UNSUPPORTED,
      'Price identifier not supported'
    );
    delete pairs[priceIdentifierHex];
    emit RemovePair(priceIdentifierHex);
  }

  //----------------------------------------
  // Public view functions
  //----------------------------------------
  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return Pair data
   */
  function pair(bytes32 _identifier)
    public
    view
    virtual
    returns (PairData memory)
  {
    return _pair(_identifier);
  }

  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier Name of the pair identifier
   * @return Pair data
   */
  function pair(string calldata _identifier)
    public
    view
    virtual
    returns (PairData memory)
  {
    return _pair(_identifier.stringToBytes32());
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId HexName of price identifier
   * @return isSupported True fi supporteed, otherwise false
   */
  function isPriceSupported(bytes32 _priceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return pairs[_priceId].priceType != Type.UNSUPPORTED;
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId Name of price identifier
   * @return isSupported True fi supported, otherwise false
   */
  function isPriceSupported(string calldata _priceId)
    public
    view
    virtual
    returns (bool)
  {
    return pairs[_priceId.stringToBytes32()].priceType != Type.UNSUPPORTED;
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice Only synthereum price-feed and off-chain calls can call this function
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function getLatestPrice(bytes32 _priceId)
    public
    view
    virtual
    override
    onlyPriceFeed
    returns (uint256)
  {
    return _getLatestPrice(_priceId);
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice This function can be called just for off-chain use
   * @param _priceId Name of price identifier
   * @return Oracle price
   */
  function getLatestPrice(string calldata _priceId)
    public
    view
    virtual
    onlyCall
    returns (uint256)
  {
    return _getLatestPrice(_priceId.stringToBytes32());
  }

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function getMaxSpread(bytes32 _priceId)
    public
    view
    virtual
    override
    returns (uint64)
  {
    return _getMaxSpread(_priceId);
  }

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId Name of price identifier
   * @return Max spread
   */
  function getMaxSpread(string calldata _priceId)
    public
    view
    virtual
    returns (uint64)
  {
    return _getMaxSpread(_priceId.stringToBytes32());
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return pairData Pair data
   */
  function _pair(bytes32 _identifier)
    internal
    view
    virtual
    returns (PairData memory pairData)
  {
    pairData = pairs[_identifier];
    require(pairData.priceType != Type.UNSUPPORTED, 'Pair not supported');
  }

  /**
   * @notice Get last price for a given price identifier
   * @param _priceId HexName of price identifier
   * @return price Oracle price
   */
  function _getLatestPrice(bytes32 _priceId)
    internal
    view
    virtual
    returns (uint256 price)
  {
    PairData storage pairData = pairs[_priceId];
    if (pairs[_priceId].priceType == Type.NORMAL) {
      price = _getStandardPrice(
        _priceId,
        pairData.source,
        pairData.conversionUnit,
        pairData.extraData
      );
    } else if (pairs[_priceId].priceType == Type.REVERSE) {
      price = _getReversePrice(
        _priceId,
        pairData.source,
        pairData.conversionUnit,
        pairData.extraData
      );
    } else {
      revert('Pair not supported');
    }
  }

  /**
   * @notice Retrieve from a source the standard price of a given pair
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _conversionUnit Conversion rate
   * @param _extraData Extra data of the pair for getting info
   * @return 18 decimals scaled price of the pair
   */
  function _getStandardPrice(
    bytes32 _priceId,
    address _source,
    uint256 _conversionUnit,
    bytes memory _extraData
  ) internal view virtual returns (uint256) {
    (uint256 unscaledPrice, uint8 decimals) = _getOracleLatestRoundPrice(
      _priceId,
      _source,
      _extraData
    );
    return _getScaledValue(unscaledPrice, decimals, _conversionUnit);
  }

  /**
   * @notice Retrieve from a source the reverse price of a given pair
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _conversionUnit Conversion rate
   * @param _extraData Extra data of the pair for getting info
   * @return 18 decimals scaled price of the pair
   */
  function _getReversePrice(
    bytes32 _priceId,
    address _source,
    uint256 _conversionUnit,
    bytes memory _extraData
  ) internal view virtual returns (uint256) {
    (uint256 unscaledPrice, uint8 decimals) = _getOracleLatestRoundPrice(
      _priceId,
      _source,
      _extraData
    );
    return
      PreciseUnitMath.DOUBLE_PRECISE_UNIT /
      _getScaledValue(unscaledPrice, decimals, _conversionUnit);
  }

  /**
   * @notice Get last oracle price for an input source
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _extraData Extra data of the pair for getting info
   * @return price Price get from the source oracle
   * @return decimals Decimals of the price
   */
  function _getOracleLatestRoundPrice(
    bytes32 _priceId,
    address _source,
    bytes memory _extraData
  ) internal view virtual returns (uint256 price, uint8 decimals);

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function _getMaxSpread(bytes32 _priceId)
    internal
    view
    virtual
    returns (uint64)
  {
    PairData storage pairData = pairs[_priceId];
    require(
      pairData.priceType != Type.UNSUPPORTED,
      'Price identifier not supported'
    );
    uint64 pairMaxSpread = pairData.maxSpread;
    return
      pairMaxSpread != 0
        ? pairMaxSpread
        : _getDynamicMaxSpread(_priceId, pairData.source, pairData.extraData);
  }

  /**
   * @notice Get the max update spread for a given price identifier dinamically
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _extraData Extra data of the pair for getting info
   * @return Max spread
   */
  function _getDynamicMaxSpread(
    bytes32 _priceId,
    address _source,
    bytes memory _extraData
  ) internal view virtual returns (uint64);

  //----------------------------------------
  // Internal pure functions
  //----------------------------------------
  /**
   * @notice Covert the price to a integer with 18 decimals
   * @param _unscaledPrice Price before conversion
   * @param _decimals Number of decimals of unconverted price
   * @return price Price after conversion
   */
  function _getScaledValue(
    uint256 _unscaledPrice,
    uint8 _decimals,
    uint256 _convertionUnit
  ) internal pure virtual returns (uint256 price) {
    price = _unscaledPrice * (10**(18 - _decimals));
    if (_convertionUnit != 0) {
      price = _convertMetricUnitPrice(price, _convertionUnit);
    }
  }

  /**
   * @notice Covert the price to a different metric unit - example troyounce to grams
   * @param _price Scaled price before convertion
   * @param _conversionUnit The metric unit convertion rate
   * @return Price after conversion
   */
  function _convertMetricUnitPrice(uint256 _price, uint256 _conversionUnit)
    internal
    pure
    virtual
    returns (uint256)
  {
    return _price.div(_conversionUnit);
  }
}
