// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RecipeCodec} from "../../src/libraries/RecipeCodec.sol";

contract RecipeCodecFuzzTest is Test {
    function testFuzz_packYulMatchesSolidity(uint128 resourceId, uint128 amount) external pure {
        assertEq(RecipeCodec.packYul(resourceId, amount), RecipeCodec.packSolidity(resourceId, amount));
    }

    function testFuzz_unpackRoundTrip(uint128 resourceId, uint128 amount) external pure {
        uint256 packed = RecipeCodec.packYul(resourceId, amount);
        (uint128 unpackedResourceId, uint128 unpackedAmount) = RecipeCodec.unpackSolidity(packed);

        assertEq(unpackedResourceId, resourceId);
        assertEq(unpackedAmount, amount);
    }
}
