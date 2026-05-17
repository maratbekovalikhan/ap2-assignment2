// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ResourceFactory} from "../../src/amm/ResourceFactory.sol";
import {ResourcePair} from "../../src/amm/ResourcePair.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";

contract ResourceFactoryTest is Test {
    ResourceFactory internal factory;

    function setUp() external {
        factory = new ResourceFactory(address(this));
    }

    function test_deployResourceTracksIdsAndMappings() external {
        (uint256 resourceId, address tokenAddress) =
            factory.deployResource("Gold", "GLD", address(this), address(this), 1_000 ether);

        ResourceToken token = ResourceToken(tokenAddress);

        assertEq(resourceId, 1);
        assertEq(factory.nextResourceId(), 1);
        assertEq(factory.resourceById(resourceId), tokenAddress);
        assertEq(factory.resourceIdOf(tokenAddress), resourceId);
        assertEq(token.totalSupply(), 1_000 ether);
    }

    function test_deployPairMatchesPredictedCreate2Address() external {
        (, address gold) = factory.deployResource("Gold", "GLD", address(this), address(this), 1_000 ether);
        (, address wood) = factory.deployResource("Wood", "WOOD", address(this), address(this), 1_000 ether);

        address predicted = factory.predictPairAddress(gold, wood);
        address actual = factory.deployPair(gold, wood);

        ResourcePair pair = ResourcePair(actual);

        assertEq(actual, predicted);
        assertEq(factory.getPair(gold, wood), actual);
        assertEq(factory.getPair(wood, gold), actual);
        assertEq(pair.token0(), gold < wood ? gold : wood);
        assertEq(pair.token1(), gold < wood ? wood : gold);
    }

    function test_cannotDeployDuplicatePair() external {
        (, address gold) = factory.deployResource("Gold", "GLD", address(this), address(this), 1_000 ether);
        (, address wood) = factory.deployResource("Wood", "WOOD", address(this), address(this), 1_000 ether);

        factory.deployPair(gold, wood);

        vm.expectRevert(bytes("pair exists"));
        factory.deployPair(wood, gold);
    }
}
