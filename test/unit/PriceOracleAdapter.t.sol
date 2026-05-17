// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "../../src/mocks/MockV3Aggregator.sol";
import {PriceOracleAdapter} from "../../src/oracle/PriceOracleAdapter.sol";

contract PriceOracleAdapterTest is Test {
    MockV3Aggregator internal feed;
    PriceOracleAdapter internal oracle;

    function setUp() external {
        feed = new MockV3Aggregator(8, 3_000e8, "ETH / USD");
        oracle = new PriceOracleAdapter(address(feed), 1 hours);
    }

    function test_quoteToUsdScalesToWad() external view {
        uint256 quote = oracle.quoteToUsd(1 ether, 18);
        assertEq(quote, 3_000 ether);
    }

    function test_revertsOnStalePrice() external {
        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert();
        oracle.latestAnswer();
    }
}
