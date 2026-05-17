// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ResourcePair} from "../../src/amm/ResourcePair.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";

contract ResourcePairFuzzTest is Test {
    ResourceToken internal gold;
    ResourceToken internal wood;
    ResourcePair internal pair;
    address internal bob = address(0xB0B);

    function setUp() external {
        gold = new ResourceToken("Gold", "GLD", address(this), address(this), 1_000_000 ether);
        wood = new ResourceToken("Wood", "WOOD", address(this), address(this), 1_000_000 ether);
        pair = new ResourcePair(address(gold), address(wood));

        gold.approve(address(pair), type(uint256).max);
        wood.approve(address(pair), type(uint256).max);
        pair.addLiquidity(100_000 ether, 100_000 ether, 100_000 ether, 100_000 ether, address(this));

        gold.mint(bob, 50_000 ether);
        wood.mint(bob, 50_000 ether);

        vm.prank(bob);
        gold.approve(address(pair), type(uint256).max);
        vm.prank(bob);
        wood.approve(address(pair), type(uint256).max);
    }

    function testFuzz_getAmountOutIsAlwaysLessThanReserveOut(
        uint96 amountInSeed,
        uint96 reserveInSeed,
        uint96 reserveOutSeed
    ) external view {
        uint256 amountIn = bound(uint256(amountInSeed), 1, 1_000_000 ether);
        uint256 reserveIn = bound(uint256(reserveInSeed), 1, 1_000_000 ether);
        uint256 reserveOut = bound(uint256(reserveOutSeed), 1, 1_000_000 ether);

        uint256 amountOut = pair.getAmountOut(amountIn, reserveIn, reserveOut);
        assertLt(amountOut, reserveOut);
    }

    function testFuzz_largerInputsNeverProduceSmallerOutputs(
        uint96 reserveInSeed,
        uint96 reserveOutSeed,
        uint96 smallInputSeed,
        uint96 extraInputSeed
    ) external view {
        uint256 reserveIn = bound(uint256(reserveInSeed), 1 ether, 1_000_000 ether);
        uint256 reserveOut = bound(uint256(reserveOutSeed), 1 ether, 1_000_000 ether);
        uint256 smallInput = bound(uint256(smallInputSeed), 1, 10_000 ether);
        uint256 largeInput = smallInput + bound(uint256(extraInputSeed), 1, 10_000 ether);

        uint256 smallOutput = pair.getAmountOut(smallInput, reserveIn, reserveOut);
        uint256 largeOutput = pair.getAmountOut(largeInput, reserveIn, reserveOut);

        assertGe(largeOutput, smallOutput);
    }

    function testFuzz_swapDoesNotDecreaseConstantProduct(uint96 amountInSeed) external {
        uint256 amountIn = bound(uint256(amountInSeed), 1 ether, 10_000 ether);
        (uint112 reserve0Before, uint112 reserve1Before) = pair.getReserves();
        uint256 kBefore = uint256(reserve0Before) * uint256(reserve1Before);

        vm.prank(bob);
        pair.swap(address(gold), amountIn, 1, bob);

        (uint112 reserve0After, uint112 reserve1After) = pair.getReserves();
        uint256 kAfter = uint256(reserve0After) * uint256(reserve1After);

        assertGe(kAfter, kBefore);
    }
}
