// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CraftingStation} from "../../src/crafting/CraftingStation.sol";
import {GameItems1155Upgradeable} from "../../src/core/GameItems1155Upgradeable.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";
import {RecipeCodec} from "../../src/libraries/RecipeCodec.sol";

contract CraftingStationFuzzTest is Test {
    CraftingStation internal craftingStation;
    GameItems1155Upgradeable internal items;
    ResourceToken internal gold;

    address internal alice = address(0xA11CE);
    address internal feeCollector = address(0xFEE1);

    function setUp() external {
        GameItems1155Upgradeable implementation = new GameItems1155Upgradeable();
        bytes memory initData =
            abi.encodeCall(GameItems1155Upgradeable.initialize, ("ipfs://items/{id}.json", address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        items = GameItems1155Upgradeable(address(proxy));

        gold = new ResourceToken("Gold", "GLD", address(this), alice, 100_000 ether);
        craftingStation = new CraftingStation(address(this), address(items), feeCollector);
        items.grantRole(items.MINTER_ROLE(), address(craftingStation));
        craftingStation.registerResource(1, address(gold));

        vm.prank(alice);
        gold.approve(address(craftingStation), type(uint256).max);
    }

    function testFuzz_craftTransfersResourcesAndMintsOutput(
        uint96 ingredientSeed,
        uint8 outputSeed,
        uint8 batchesSeed,
        uint256 itemIdSeed
    ) external {
        uint256 ingredientAmount = bound(uint256(ingredientSeed), 1 ether, 100 ether);
        uint256 outputAmount = bound(uint256(outputSeed), 1, 10);
        uint256 batches = bound(uint256(batchesSeed), 1, 25);
        uint256 itemId = bound(itemIdSeed, 1, type(uint32).max);

        uint256[] memory ingredients = new uint256[](1);
        ingredients[0] = RecipeCodec.packYul(1, uint128(ingredientAmount));
        craftingStation.setRecipe(itemId, outputAmount, ingredients);

        vm.prank(alice);
        craftingStation.craft(itemId, batches);

        assertEq(items.balanceOf(alice, itemId), outputAmount * batches);
        assertEq(gold.balanceOf(feeCollector), ingredientAmount * batches);
    }

    function testFuzz_recipeOverwriteUsesLatestConfiguration(
        uint96 firstIngredientSeed,
        uint96 secondIngredientSeed,
        uint8 firstOutputSeed,
        uint8 secondOutputSeed,
        uint256 itemIdSeed
    ) external {
        uint256 firstIngredient = bound(uint256(firstIngredientSeed), 1 ether, 25 ether);
        uint256 secondIngredient = bound(uint256(secondIngredientSeed), 1 ether, 25 ether);
        uint256 firstOutput = bound(uint256(firstOutputSeed), 1, 5);
        uint256 secondOutput = bound(uint256(secondOutputSeed), 1, 5);
        uint256 itemId = bound(itemIdSeed, 1, type(uint32).max);

        uint256[] memory firstRecipe = new uint256[](1);
        firstRecipe[0] = RecipeCodec.packYul(1, uint128(firstIngredient));

        uint256[] memory secondRecipe = new uint256[](1);
        secondRecipe[0] = RecipeCodec.packYul(1, uint128(secondIngredient));

        craftingStation.setRecipe(itemId, firstOutput, firstRecipe);
        craftingStation.setRecipe(itemId, secondOutput, secondRecipe);

        vm.prank(alice);
        craftingStation.craft(itemId, 1);

        assertEq(items.balanceOf(alice, itemId), secondOutput);
        assertEq(gold.balanceOf(feeCollector), secondIngredient);
    }

    function testFuzz_nonRecipeRoleCannotSetRecipe(uint256 itemIdSeed, uint8 outputSeed) external {
        uint256 itemId = bound(itemIdSeed, 1, type(uint32).max);
        uint256 outputAmount = bound(uint256(outputSeed), 1, 10);
        uint256[] memory ingredients = new uint256[](1);
        ingredients[0] = RecipeCodec.packYul(1, 1 ether);

        vm.prank(alice);
        vm.expectRevert();
        craftingStation.setRecipe(itemId, outputAmount, ingredients);
    }
}
