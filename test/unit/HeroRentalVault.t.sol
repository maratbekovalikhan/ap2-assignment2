// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HeroNFT} from "../../src/core/HeroNFT.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";
import {MockV3Aggregator} from "../../src/mocks/MockV3Aggregator.sol";
import {PriceOracleAdapter} from "../../src/oracle/PriceOracleAdapter.sol";
import {HeroRentalVault} from "../../src/rentals/HeroRentalVault.sol";
import {RentalRevenueVault} from "../../src/rentals/RentalRevenueVault.sol";

contract HeroRentalVaultTest is Test {
    HeroNFT internal heroNft;
    ResourceToken internal gold;
    MockV3Aggregator internal feed;
    PriceOracleAdapter internal oracle;
    RentalRevenueVault internal revenueVault;
    HeroRentalVault internal heroRentalVault;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() external {
        heroNft = new HeroNFT("LootForge Heroes", "LFH", "ipfs://heroes/", address(this));
        gold = new ResourceToken("Gold", "GLD", address(this), bob, 10_000 ether);
        feed = new MockV3Aggregator(8, 3_000e8, "ETH / USD");
        oracle = new PriceOracleAdapter(address(feed), 1 hours);
        revenueVault = new RentalRevenueVault(address(gold), address(this));
        heroRentalVault = new HeroRentalVault(address(this), address(heroNft), address(revenueVault), address(oracle));

        revenueVault.grantRole(revenueVault.REVENUE_ROLE(), address(heroRentalVault));

        vm.prank(bob);
        gold.approve(address(revenueVault), type(uint256).max);

        vm.deal(alice, 1 ether);
        vm.deal(bob, 5 ether);
    }

    function test_depositAndWithdrawHero() external {
        uint256 heroId = heroNft.mint(alice);

        vm.prank(alice);
        heroNft.approve(address(heroRentalVault), heroId);

        vm.prank(alice);
        heroRentalVault.depositHero(heroId, 10 ether, 100 ether);

        assertEq(heroNft.ownerOf(heroId), address(heroRentalVault));

        vm.prank(alice);
        heroRentalVault.withdrawHero(heroId, alice);

        assertEq(heroNft.ownerOf(heroId), alice);
    }

    function test_rentAndCloseReturnsCollateralToRenter() external {
        uint256 heroId = _depositListing();
        uint256 bobBalanceBefore = bob.balance;

        vm.prank(bob);
        heroRentalVault.rentHero{value: 1 ether}(heroId, 1);

        assertTrue(heroRentalVault.canUseHero(heroId, bob));
        assertEq(gold.balanceOf(address(revenueVault)), 25 ether);
        assertEq(bob.balance, bobBalanceBefore - 1 ether);

        vm.prank(bob);
        heroRentalVault.closeRental(heroId);

        assertFalse(heroRentalVault.canUseHero(heroId, bob));
        assertEq(bob.balance, bobBalanceBefore);
    }

    function test_overdueClosePaysCollateralToOwner() external {
        uint256 heroId = _depositListing();
        uint256 ownerBalanceBefore = alice.balance;

        vm.prank(bob);
        heroRentalVault.rentHero{value: 1 ether}(heroId, 1);

        vm.warp(block.timestamp + 2 days);

        vm.prank(alice);
        heroRentalVault.closeRental(heroId);

        assertEq(alice.balance, ownerBalanceBefore + 1 ether);
    }

    function test_pauseBlocksRenting() external {
        uint256 heroId = _depositListing();

        heroRentalVault.pause();

        vm.prank(bob);
        vm.expectRevert();
        heroRentalVault.rentHero{value: 1 ether}(heroId, 1);
    }

    function _depositListing() internal returns (uint256 heroId) {
        heroId = heroNft.mint(alice);

        vm.prank(alice);
        heroNft.approve(address(heroRentalVault), heroId);

        vm.prank(alice);
        heroRentalVault.depositHero(heroId, 25 ether, 500 ether);
    }
}
