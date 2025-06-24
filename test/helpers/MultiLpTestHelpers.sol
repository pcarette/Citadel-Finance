// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {ISynthereumMultiLpLiquidityPool} from "../../src/pool/interfaces/IMultiLpLiquidityPool.sol";

/// @title MultiLpTestHelpers
/// @notice Helper functions for MultiLpLiquidityPool tests
library MultiLpTestHelpers {
    /// @notice Calculates fee, net amount, and tokens for minting
    function calculateFeeAndSynthAssetForMint(
        uint256 feePrc,
        uint256 collAmount,
        uint256 price,
        uint8 collateralDecimals,
        uint256 preciseUnit
    ) internal pure returns (
        uint256 feeAmount,
        uint256 netAmount,
        uint256 tokensAmount
    ) {
        feeAmount = (collAmount * feePrc) / preciseUnit;
        netAmount = collAmount - feeAmount;
        uint256 factor = 10 ** (18 - collateralDecimals);
        tokensAmount = (netAmount * factor * preciseUnit) / price;
    }

    /// @notice Calculates fee, net amount, and collateral for redeeming
    function calculateFeeAndCollateralForRedeem(
        uint256 feePrc,
        uint256 synthAmount,
        uint256 price,
        uint8 collateralDecimals,
        uint256 preciseUnit
    ) internal pure returns (
        uint256 feeAmount,
        uint256 netAmount,
        uint256 collAmount
    ) {
        feeAmount = (synthAmount * feePrc) / preciseUnit;
        netAmount = synthAmount - feeAmount;
        uint256 factor = 10 ** (18 - collateralDecimals);
        collAmount = (netAmount * price) / preciseUnit / factor;
    }

    function getLessCollateralizedLP(ISynthereumMultiLpLiquidityPool poolInstance) public view returns (address lessCollateralizedLP, uint256 coverage, uint256 tokens) {
        address[] memory activeLps = poolInstance.getActiveLPs();
        lessCollateralizedLP = activeLps[0];
        coverage = poolInstance.positionLPInfo(lessCollateralizedLP).coverage;
        tokens = poolInstance.positionLPInfo(lessCollateralizedLP).tokensCollateralized;
        for (uint8 i = 0; i < activeLps.length ; ++i) {
            if (poolInstance.positionLPInfo(activeLps[i]).actualCollateralAmount < poolInstance.positionLPInfo(lessCollateralizedLP).actualCollateralAmount) {
                lessCollateralizedLP = activeLps[i];
                tokens = poolInstance.positionLPInfo(activeLps[i]).tokensCollateralized;
                coverage = poolInstance.positionLPInfo(activeLps[i]).coverage;
            }
        }
    }
}