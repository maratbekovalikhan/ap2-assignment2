// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    AggregatorV3Interface
} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public immutable override decimals;
    string public override description;
    uint256 public constant override version = 1;

    int256 private _answer;
    uint80 private _roundId;
    uint256 private _updatedAt;

    constructor(uint8 decimals_, int256 initialAnswer, string memory description_) {
        decimals = decimals_;
        description = description_;
        _setAnswer(initialAnswer);
    }

    function updateAnswer(int256 newAnswer) external {
        _setAnswer(newAnswer);
    }

    function getRoundData(uint80 roundId) external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, _answer, _updatedAt, _updatedAt, roundId);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    function _setAnswer(int256 newAnswer) internal {
        _roundId += 1;
        _answer = newAnswer;
        _updatedAt = block.timestamp;
    }
}
