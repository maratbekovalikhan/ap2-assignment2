// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {GameItems1155Upgradeable} from "../../src/core/GameItems1155Upgradeable.sol";
import {GameItems1155V2} from "../../src/core/GameItems1155V2.sol";

contract GameItemsUpgradeTest is Test {
    GameItems1155Upgradeable internal items;
    address internal alice = address(0xA11CE);

    function setUp() external {
        GameItems1155Upgradeable implementation = new GameItems1155Upgradeable();
        bytes memory initData =
            abi.encodeCall(GameItems1155Upgradeable.initialize, ("ipfs://items/{id}.json", address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        items = GameItems1155Upgradeable(address(proxy));
    }

    function test_upgradeToV2AndSetCap() external {
        items.mint(alice, 1, 1, "");

        GameItems1155V2 newImplementation = new GameItems1155V2();
        items.upgradeToAndCall(address(newImplementation), "");

        GameItems1155V2 upgraded = GameItems1155V2(address(items));
        upgraded.setSupplyCap(1, 2);
        upgraded.mint(alice, 1, 1, "");

        vm.expectRevert();
        upgraded.mint(alice, 1, 1, "");
    }
}
