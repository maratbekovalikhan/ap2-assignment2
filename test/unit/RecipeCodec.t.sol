// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RecipeCodec} from "../../src/libraries/RecipeCodec.sol";

contract RecipeCodecHarness {
    function packYul(uint128 resourceId, uint128 amount) external pure returns (uint256) {
        return RecipeCodec.packYul(resourceId, amount);
    }

    function unpackYul(uint256 packed) external pure returns (uint128, uint128) {
        return RecipeCodec.unpackYul(packed);
    }

    function packSolidity(uint128 resourceId, uint128 amount) external pure returns (uint256) {
        return RecipeCodec.packSolidity(resourceId, amount);
    }

    function unpackSolidity(uint256 packed) external pure returns (uint128, uint128) {
        return RecipeCodec.unpackSolidity(packed);
    }
}

contract RecipeCodecTest is Test {
    RecipeCodecHarness internal harness;

    function setUp() external {
        harness = new RecipeCodecHarness();
    }

    function test_packAndUnpackYulMatchesSolidity() external view {
        uint128 resourceId = 77;
        uint128 amount = 2_500 ether;

        uint256 yulPacked = harness.packYul(resourceId, amount);
        uint256 solidityPacked = harness.packSolidity(resourceId, amount);

        assertEq(yulPacked, solidityPacked);

        (uint128 unpackedResourceId, uint128 unpackedAmount) = harness.unpackYul(yulPacked);
        assertEq(unpackedResourceId, resourceId);
        assertEq(unpackedAmount, amount);
    }
}
