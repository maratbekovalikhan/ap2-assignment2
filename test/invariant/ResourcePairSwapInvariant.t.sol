// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {ResourcePair} from "../../src/amm/ResourcePair.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";

contract ResourcePairSwapHandler is Test {
    ResourcePair internal pair;
    ResourceToken internal gold;
    ResourceToken internal wood;

    constructor(ResourcePair pair_, ResourceToken gold_, ResourceToken wood_) {
        pair = pair_;
        gold = gold_;
        wood = wood_;

        gold.approve(address(pair_), type(uint256).max);
        wood.approve(address(pair_), type(uint256).max);
    }

    function swapGoldForWood(uint256 amountInSeed) external {
        uint256 balance = gold.balanceOf(address(this));
        if (balance == 0) return;

        uint256 amountIn = bound(amountInSeed, 1, balance);
        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        if (pair.getAmountOut(amountIn, reserve0, reserve1) == 0) return;

        pair.swap(address(gold), amountIn, 1, address(this));
    }

    function swapWoodForGold(uint256 amountInSeed) external {
        uint256 balance = wood.balanceOf(address(this));
        if (balance == 0) return;

        uint256 amountIn = bound(amountInSeed, 1, balance);
        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        if (pair.getAmountOut(amountIn, reserve1, reserve0) == 0) return;

        pair.swap(address(wood), amountIn, 1, address(this));
    }
}

contract ResourcePairSwapInvariantTest is StdInvariant, Test {
    ResourceToken internal gold;
    ResourceToken internal wood;
    ResourcePair internal pair;
    ResourcePairSwapHandler internal handler;

    uint256 internal initialK;
    uint256 internal initialLpSupply;

    function setUp() external {
        gold = new ResourceToken("Gold", "GLD", address(this), address(this), 1_000_000 ether);
        wood = new ResourceToken("Wood", "WOOD", address(this), address(this), 1_000_000 ether);
        pair = new ResourcePair(address(gold), address(wood));

        gold.approve(address(pair), type(uint256).max);
        wood.approve(address(pair), type(uint256).max);
        pair.addLiquidity(100_000 ether, 100_000 ether, 100_000 ether, 100_000 ether, address(this));

        handler = new ResourcePairSwapHandler(pair, gold, wood);
        gold.mint(address(handler), 25_000 ether);
        wood.mint(address(handler), 25_000 ether);

        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        initialK = uint256(reserve0) * uint256(reserve1);
        initialLpSupply = pair.totalSupply();

        targetContract(address(handler));
    }

    function invariant_constantProductDoesNotDecreaseDuringSwaps() external view {
        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        uint256 currentK = uint256(reserve0) * uint256(reserve1);
        assertGe(currentK, initialK);
    }

    function invariant_reservesAlwaysMatchPairBalances() external view {
        (uint112 reserve0, uint112 reserve1) = pair.getReserves();
        assertEq(uint256(reserve0), gold.balanceOf(address(pair)));
        assertEq(uint256(reserve1), wood.balanceOf(address(pair)));
    }

    function invariant_lpSupplyRemainsConstantWhenOnlySwapping() external view {
        assertEq(pair.totalSupply(), initialLpSupply);
    }
}
