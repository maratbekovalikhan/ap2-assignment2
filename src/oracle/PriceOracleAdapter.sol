// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    AggregatorV3Interface
} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceOracleAdapter {
    AggregatorV3Interface public immutable feed;
    uint256 public immutable maxStaleness;
    uint8 public immutable feedDecimals;

    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt, uint256 maxStaleness, uint256 currentTimestamp);

    constructor(address feed_, uint256 maxStaleness_) {
        require(feed_ != address(0), "feed=0");
        require(maxStaleness_ != 0, "staleness=0");

        feed = AggregatorV3Interface(feed_);
        maxStaleness = maxStaleness_;
        feedDecimals = feed.decimals();
    }

    function latestAnswer() public view returns (uint256 answer, uint256 updatedAt) {
        (, int256 rawAnswer,, uint256 rawUpdatedAt,) = feed.latestRoundData();

        if (rawAnswer <= 0) {
            revert InvalidPrice(rawAnswer);
        }

        if (block.timestamp > rawUpdatedAt + maxStaleness) {
            revert StalePrice(rawUpdatedAt, maxStaleness, block.timestamp);
        }

        return (uint256(rawAnswer), rawUpdatedAt);
    }

    function latestAnswerWad() public view returns (uint256) {
        (uint256 answer,) = latestAnswer();
        return _scale(answer, feedDecimals, 18);
    }

    function quoteToUsd(uint256 assetAmount, uint8 assetDecimals) external view returns (uint256) {
        uint256 priceWad = latestAnswerWad();
        return (assetAmount * priceWad) / (10 ** assetDecimals);
    }

    function _scale(uint256 value, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return value;
        }

        if (fromDecimals < toDecimals) {
            return value * (10 ** (toDecimals - fromDecimals));
        }

        return value / (10 ** (fromDecimals - toDecimals));
    }
}
