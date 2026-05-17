// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {GameItems1155Upgradeable} from "../src/core/GameItems1155Upgradeable.sol";
import {GameItems1155V2} from "../src/core/GameItems1155V2.sol";

contract UpgradeGameItems is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxy = vm.envAddress("ITEMS_PROXY");

        vm.startBroadcast(privateKey);

        GameItems1155V2 v2Implementation = new GameItems1155V2();
        GameItems1155Upgradeable(proxy).upgradeToAndCall(address(v2Implementation), "");

        vm.stopBroadcast();

        console2.log("New implementation:", address(v2Implementation));
    }
}
