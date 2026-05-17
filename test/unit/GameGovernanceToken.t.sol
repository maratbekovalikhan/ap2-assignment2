// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameGovernanceToken} from "../../src/core/GameGovernanceToken.sol";

contract GameGovernanceTokenTest is Test {
    GameGovernanceToken internal token;
    address internal alice = address(0xA11CE);

    function setUp() external {
        token = new GameGovernanceToken("LootForge Governance", "LFGOV", address(this), address(this), 1_000_000 ether);
        token.mint(alice, 10_000 ether);
    }

    function test_delegateCreatesVotingPower() external {
        vm.prank(alice);
        token.delegate(alice);

        vm.warp(block.timestamp + 1);
        assertEq(token.getVotes(alice), 10_000 ether);
    }
}
