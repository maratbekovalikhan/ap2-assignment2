// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {GameGovernanceToken} from "../src/core/GameGovernanceToken.sol";
import {GameGovernor} from "../src/governance/GameGovernor.sol";
import {GameItems1155Upgradeable} from "../src/core/GameItems1155Upgradeable.sol";
import {HeroNFT} from "../src/core/HeroNFT.sol";
import {ResourceFactory} from "../src/amm/ResourceFactory.sol";
import {PriceOracleAdapter} from "../src/oracle/PriceOracleAdapter.sol";
import {RentalRevenueVault} from "../src/rentals/RentalRevenueVault.sol";
import {HeroRentalVault} from "../src/rentals/HeroRentalVault.sol";
import {CraftingStation} from "../src/crafting/CraftingStation.sol";

contract DeployLocal is Script {
    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        address deployer = vm.addr(privateKey);

        GameGovernanceToken governanceToken =
            new GameGovernanceToken("LootForge Governance", "LFGOV", deployer, deployer, INITIAL_SUPPLY);
        governanceToken.delegate(deployer);

        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);

        TimelockController timelock = new TimelockController(2 days, proposers, executors, deployer);
        GameGovernor governor = new GameGovernor(governanceToken, timelock, INITIAL_SUPPLY / 100);

        proposers[0] = address(governor);
        executors[0] = address(0);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        ResourceFactory resourceFactory = new ResourceFactory(deployer);
        (, address goldToken) = resourceFactory.deployResource("Gold", "GLD", deployer, deployer, 10_000_000 ether);

        RentalRevenueVault revenueVault = new RentalRevenueVault(goldToken, deployer);
        PriceOracleAdapter oracle = new PriceOracleAdapter(vm.envAddress("PRICE_FEED"), 1 hours);
        HeroNFT heroNFT = new HeroNFT("LootForge Heroes", "LFH", "ipfs://heroes/", deployer);

        GameItems1155Upgradeable itemsImplementation = new GameItems1155Upgradeable();
        bytes memory initData =
            abi.encodeCall(GameItems1155Upgradeable.initialize, ("ipfs://items/{id}.json", deployer));
        ERC1967Proxy proxy = new ERC1967Proxy(address(itemsImplementation), initData);
        GameItems1155Upgradeable items = GameItems1155Upgradeable(address(proxy));

        HeroRentalVault heroRentalVault =
            new HeroRentalVault(deployer, address(heroNFT), address(revenueVault), address(oracle));
        CraftingStation craftingStation = new CraftingStation(deployer, address(items), address(revenueVault));

        items.grantRole(items.MINTER_ROLE(), address(craftingStation));
        revenueVault.grantRole(revenueVault.REVENUE_ROLE(), address(heroRentalVault));

        vm.stopBroadcast();

        console2.log("Governance token:", address(governanceToken));
        console2.log("Governor:", address(governor));
        console2.log("Timelock:", address(timelock));
        console2.log("Gold token:", goldToken);
        console2.log("Items proxy:", address(items));
        console2.log("Revenue vault:", address(revenueVault));
        console2.log("Hero rental vault:", address(heroRentalVault));
        console2.log("Crafting station:", address(craftingStation));
    }
}
