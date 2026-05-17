// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {VRFConsumerBaseV2} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {
    VRFCoordinatorV2Interface
} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

interface ILootItemsMintable {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract LootDropManager is AccessControl, VRFConsumerBaseV2 {
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    struct DropOption {
        uint256 itemId;
        uint96 weight;
        uint96 amount;
    }

    struct LootRequest {
        address player;
        uint256 chestType;
    }

    ILootItemsMintable public immutable items;
    VRFCoordinatorV2Interface public immutable coordinator;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    uint16 public immutable requestConfirmations;
    uint32 public immutable callbackGasLimit;

    mapping(uint256 chestType => DropOption[]) private _dropTableByChestType;
    mapping(uint256 requestId => LootRequest request) public requests;

    event LootRequested(uint256 indexed requestId, address indexed player, uint256 indexed chestType);
    event LootFulfilled(
        uint256 indexed requestId, address indexed player, uint256 chestType, uint256 itemId, uint256 amount
    );
    event DropTableSet(uint256 indexed chestType, uint256 optionCount);

    constructor(
        address admin,
        address items_,
        address coordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) VRFConsumerBaseV2(coordinator_) {
        require(admin != address(0), "admin=0");
        require(items_ != address(0), "items=0");
        require(coordinator_ != address(0), "coordinator=0");

        items = ILootItemsMintable(items_);
        coordinator = VRFCoordinatorV2Interface(coordinator_);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CONFIG_ROLE, admin);
    }

    function setDropTable(
        uint256 chestType,
        uint256[] calldata itemIds,
        uint96[] calldata weights,
        uint96[] calldata amounts
    ) external onlyRole(CONFIG_ROLE) {
        uint256 length = itemIds.length;
        require(length != 0 && length == weights.length && length == amounts.length, "bad lengths");

        delete _dropTableByChestType[chestType];
        for (uint256 i = 0; i < length; ++i) {
            require(weights[i] != 0 && amounts[i] != 0, "zero config");
            _dropTableByChestType[chestType].push(
                DropOption({itemId: itemIds[i], weight: weights[i], amount: amounts[i]})
            );
        }

        emit DropTableSet(chestType, length);
    }

    function getDropTable(uint256 chestType) external view returns (DropOption[] memory) {
        return _dropTableByChestType[chestType];
    }

    function requestLoot(uint256 chestType) external returns (uint256 requestId) {
        require(_dropTableByChestType[chestType].length != 0, "no drops");

        requestId = coordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, 1);
        requests[requestId] = LootRequest({player: msg.sender, chestType: chestType});

        emit LootRequested(requestId, msg.sender, chestType);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        LootRequest memory lootRequest = requests[requestId];
        require(lootRequest.player != address(0), "unknown request");

        DropOption[] storage options = _dropTableByChestType[lootRequest.chestType];
        uint256 totalWeight;
        for (uint256 i = 0; i < options.length; ++i) {
            totalWeight += options[i].weight;
        }

        uint256 randomPoint = randomWords[0] % totalWeight;
        uint256 cumulative;
        DropOption memory selected = options[0];

        for (uint256 i = 0; i < options.length; ++i) {
            cumulative += options[i].weight;
            if (randomPoint < cumulative) {
                selected = options[i];
                break;
            }
        }

        delete requests[requestId];
        items.mint(lootRequest.player, selected.itemId, selected.amount, "");

        emit LootFulfilled(requestId, lootRequest.player, lootRequest.chestType, selected.itemId, selected.amount);
    }
}
