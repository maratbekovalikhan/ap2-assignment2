// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {GameGovernanceToken} from "../../src/core/GameGovernanceToken.sol";
import {GameGovernor} from "../../src/governance/GameGovernor.sol";
import {GameItems1155Upgradeable} from "../../src/core/GameItems1155Upgradeable.sol";
import {ResourceToken} from "../../src/core/ResourceToken.sol";
import {CraftingStation} from "../../src/crafting/CraftingStation.sol";
import {RecipeCodec} from "../../src/libraries/RecipeCodec.sol";

contract GameGovernorLifecycleTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant ITEM_ID = 77;
    uint256 internal constant OUTPUT_AMOUNT = 3;

    GameGovernanceToken internal governanceToken;
    TimelockController internal timelock;
    GameGovernor internal governor;
    GameItems1155Upgradeable internal items;
    ResourceToken internal gold;
    CraftingStation internal craftingStation;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal carol = address(0xCA401);
    address internal crafter = address(0xC0FFEE);
    address internal initialCollector = address(0xFEE1);
    address internal newCollector = address(0xFEE2);

    function setUp() external {
        governanceToken =
            new GameGovernanceToken("LootForge Governance", "LFGOV", address(this), address(this), INITIAL_SUPPLY);

        governanceToken.transfer(alice, 250_000 ether);
        governanceToken.transfer(bob, 250_000 ether);
        governanceToken.transfer(carol, 250_000 ether);

        vm.prank(alice);
        governanceToken.delegate(alice);
        vm.prank(bob);
        governanceToken.delegate(bob);
        vm.prank(carol);
        governanceToken.delegate(carol);
        vm.warp(block.timestamp + 1);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new TimelockController(2 days, proposers, executors, address(this));
        governor = new GameGovernor(governanceToken, timelock, INITIAL_SUPPLY / 100);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        GameItems1155Upgradeable implementation = new GameItems1155Upgradeable();
        bytes memory initData =
            abi.encodeCall(GameItems1155Upgradeable.initialize, ("ipfs://items/{id}.json", address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        items = GameItems1155Upgradeable(address(proxy));

        gold = new ResourceToken("Gold", "GLD", address(this), crafter, 10_000 ether);
        craftingStation = new CraftingStation(address(timelock), address(items), initialCollector);

        items.grantRole(items.MINTER_ROLE(), address(craftingStation));

        vm.prank(crafter);
        gold.approve(address(craftingStation), type(uint256).max);
    }

    function test_governanceLifecycleControlsCraftingParameters() external {
        uint256[] memory ingredients = new uint256[](1);
        ingredients[0] = RecipeCodec.packYul(1, 10 ether);

        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);

        targets[0] = address(craftingStation);
        calldatas[0] = abi.encodeCall(CraftingStation.setFeeCollector, (newCollector));

        targets[1] = address(craftingStation);
        calldatas[1] = abi.encodeCall(CraftingStation.registerResource, (1, address(gold)));

        targets[2] = address(craftingStation);
        calldatas[2] = abi.encodeCall(CraftingStation.setRecipe, (ITEM_ID, OUTPUT_AMOUNT, ingredients));

        string memory description = "DAO updates crafting recipe and fee collector";
        bytes32 descriptionHash = keccak256(bytes(description));

        vm.prank(alice);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));

        vm.warp(block.timestamp + governor.votingDelay() + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        vm.prank(alice);
        governor.castVote(proposalId, 1);
        vm.prank(bob);
        governor.castVote(proposalId, 1);
        vm.prank(carol);
        governor.castVote(proposalId, 2);

        vm.warp(block.timestamp + governor.votingPeriod() + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);
        governor.execute(targets, values, calldatas, descriptionHash);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));

        assertEq(craftingStation.feeCollector(), newCollector);
        assertEq(craftingStation.resourceTokenById(1), address(gold));
        assertEq(craftingStation.outputAmountByItem(ITEM_ID), OUTPUT_AMOUNT);

        uint256[] memory recipe = craftingStation.getRecipe(ITEM_ID);
        assertEq(recipe.length, 1);
        assertEq(recipe[0], ingredients[0]);

        vm.prank(crafter);
        craftingStation.craft(ITEM_ID, 2);

        assertEq(items.balanceOf(crafter, ITEM_ID), OUTPUT_AMOUNT * 2);
        assertEq(gold.balanceOf(newCollector), 20 ether);
    }

    function test_revertsWhenProposerIsBelowThreshold() external {
        address lowVoteHolder = address(0xD00D);
        governanceToken.transfer(lowVoteHolder, 5_000 ether);

        vm.prank(lowVoteHolder);
        governanceToken.delegate(lowVoteHolder);
        vm.warp(block.timestamp + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(craftingStation);
        calldatas[0] = abi.encodeCall(CraftingStation.setFeeCollector, (newCollector));

        vm.prank(lowVoteHolder);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorInsufficientProposerVotes.selector, lowVoteHolder, 5_000 ether, INITIAL_SUPPLY / 100
            )
        );
        governor.propose(targets, values, calldatas, "under-threshold proposal");
    }
}
