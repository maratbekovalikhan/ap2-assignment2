// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CraftingStation} from "../../src/crafting/CraftingStation.sol";
import {GameItems1155Upgradeable} from "../../src/core/GameItems1155Upgradeable.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";
import {RecipeCodec} from "../../src/libraries/RecipeCodec.sol";

contract CraftingStationTest is Test {
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

        gold = new ResourceToken("Gold", "GLD", address(this), alice, 10_000 ether);
        craftingStation = new CraftingStation(address(this), address(items), feeCollector);
        items.grantRole(items.MINTER_ROLE(), address(craftingStation));

        craftingStation.registerResource(1, address(gold));

        vm.prank(alice);
        gold.approve(address(craftingStation), type(uint256).max);
    }

    function test_craftTransfersResourcesAndMintsItems() external {
        uint256[] memory ingredients = new uint256[](1);
        ingredients[0] = RecipeCodec.packYul(1, 25 ether);

        craftingStation.setRecipe(42, 2, ingredients);

        vm.prank(alice);
        craftingStation.craft(42, 3);

        assertEq(items.balanceOf(alice, 42), 6);
        assertEq(gold.balanceOf(feeCollector), 75 ether);
    }

    function test_craftRevertsWhenRecipeIsMissing() external {
        vm.prank(alice);
        vm.expectRevert(bytes("recipe missing"));
        craftingStation.craft(99, 1);
    }

    function test_onlyAdminCanSetFeeCollector() external {
        vm.prank(alice);
        vm.expectRevert();
        craftingStation.setFeeCollector(alice);
    }

    function test_onlyRecipeRoleCanRegisterResources() external {
        vm.prank(alice);
        vm.expectRevert();
        craftingStation.registerResource(2, address(gold));
    }
}
