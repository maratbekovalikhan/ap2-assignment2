// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RecipeCodec {
    uint256 internal constant LOW_128_MASK = type(uint128).max;

    function packYul(uint128 resourceId, uint128 amount) internal pure returns (uint256 packed) {
        assembly {
            packed := or(shl(128, resourceId), amount)
        }
    }

    function unpackYul(uint256 packed) internal pure returns (uint128 resourceId, uint128 amount) {
        assembly {
            resourceId := shr(128, packed)
            amount := and(packed, 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff)
        }
    }

    function packSolidity(uint128 resourceId, uint128 amount) internal pure returns (uint256) {
        return (uint256(resourceId) << 128) | uint256(amount);
    }

    function unpackSolidity(uint256 packed) internal pure returns (uint128 resourceId, uint128 amount) {
        resourceId = uint128(packed >> 128);
        amount = uint128(packed & LOW_128_MASK);
    }
}
