// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameGovernanceToken} from "../../src/core/GameGovernanceToken.sol";

contract GameGovernanceTokenFuzzTest is Test {
    GameGovernanceToken internal token;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() external {
        token = new GameGovernanceToken("LootForge Governance", "LFGOV", address(this), address(this), 2_000_000 ether);
    }

    function testFuzz_transferUpdatesDelegatedVotes(uint96 aliceAmountSeed, uint96 bobAmountSeed, uint96 transferSeed)
        external
    {
        uint256 aliceAmount = bound(uint256(aliceAmountSeed), 1 ether, 500_000 ether);
        uint256 bobAmount = bound(uint256(bobAmountSeed), 1 ether, 500_000 ether);

        token.mint(alice, aliceAmount);
        token.mint(bob, bobAmount);

        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);
        vm.warp(block.timestamp + 1);

        uint256 transferAmount = bound(uint256(transferSeed), 1, aliceAmount);
        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.getVotes(alice), aliceAmount - transferAmount);
        assertEq(token.getVotes(bob), bobAmount + transferAmount);
    }

    function testFuzz_mintIncreasesVotesForSelfDelegatedHolder(uint96 baseAmountSeed, uint96 extraAmountSeed) external {
        uint256 baseAmount = bound(uint256(baseAmountSeed), 1 ether, 250_000 ether);
        uint256 extraAmount = bound(uint256(extraAmountSeed), 1, 100_000 ether);

        token.mint(alice, baseAmount);

        vm.prank(alice);
        token.delegate(alice);
        vm.warp(block.timestamp + 1);

        uint256 votesBefore = token.getVotes(alice);
        token.mint(alice, extraAmount);

        assertEq(votesBefore, baseAmount);
        assertEq(token.getVotes(alice), baseAmount + extraAmount);
    }

    function testFuzz_holderHasNoVotingPowerUntilDelegation(uint96 amountSeed) external {
        uint256 amount = bound(uint256(amountSeed), 1 ether, 250_000 ether);
        token.mint(alice, amount);

        assertEq(token.getVotes(alice), 0);

        vm.prank(alice);
        token.delegate(alice);

        assertEq(token.getVotes(alice), amount);
    }
}
