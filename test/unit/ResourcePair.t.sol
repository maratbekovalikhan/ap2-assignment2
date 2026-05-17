// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ResourcePair} from "../../src/amm/ResourcePair.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";

contract ResourcePairTest is Test {
    ResourceToken internal gold;
    ResourceToken internal wood;
    ResourcePair internal pair;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() external {
        gold = new ResourceToken("Gold", "GLD", address(this), address(this), 1_000_000 ether);
        wood = new ResourceToken("Wood", "WOOD", address(this), address(this), 1_000_000 ether);
        pair = new ResourcePair(address(gold), address(wood));

        gold.mint(alice, 100_000 ether);
        wood.mint(alice, 100_000 ether);
        gold.mint(bob, 10_000 ether);
        wood.mint(bob, 10_000 ether);

        vm.prank(alice);
        gold.approve(address(pair), type(uint256).max);
        vm.prank(alice);
        wood.approve(address(pair), type(uint256).max);

        vm.prank(bob);
        gold.approve(address(pair), type(uint256).max);
        vm.prank(bob);
        wood.approve(address(pair), type(uint256).max);
    }

    function test_addLiquidityMintsLpShares() external {
        vm.prank(alice);
        uint256 minted = pair.addLiquidity(10_000 ether, 10_000 ether, 10_000 ether, 10_000 ether, alice);

        assertGt(minted, 0);
        assertEq(pair.balanceOf(alice), minted);
    }

    function test_swapProducesOutput() external {
        vm.prank(alice);
        pair.addLiquidity(10_000 ether, 10_000 ether, 10_000 ether, 10_000 ether, alice);

        vm.prank(bob);
        uint256 amountOut = pair.swap(address(gold), 100 ether, 1, bob);

        assertGt(amountOut, 0);
        assertEq(wood.balanceOf(bob), 10_000 ether + amountOut);
    }

    function test_removeLiquidityReturnsAssets() external {
        vm.prank(alice);
        uint256 liquidity = pair.addLiquidity(10_000 ether, 10_000 ether, 10_000 ether, 10_000 ether, alice);

        vm.prank(alice);
        pair.removeLiquidity(liquidity / 2, 1, 1, alice);

        assertGt(gold.balanceOf(alice), 90_000 ether);
        assertGt(wood.balanceOf(alice), 90_000 ether);
    }
}
