// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RecipeCodec} from "../libraries/RecipeCodec.sol";

interface IGameItemsMintable {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract CraftingStation is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant RECIPE_ROLE = keccak256("RECIPE_ROLE");

    IGameItemsMintable public immutable items;
    address public feeCollector;

    mapping(uint256 resourceId => address token) public resourceTokenById;
    mapping(uint256 itemId => uint256[] packedIngredients) private _recipeByItem;
    mapping(uint256 itemId => uint256 outputAmount) public outputAmountByItem;

    event ResourceRegistered(uint256 indexed resourceId, address indexed token);
    event RecipeSet(uint256 indexed itemId, uint256 outputAmount, uint256 ingredientCount);
    event Crafted(address indexed player, uint256 indexed itemId, uint256 amount);

    constructor(address admin, address items_, address feeCollector_) {
        require(admin != address(0), "admin=0");
        require(items_ != address(0), "items=0");
        require(feeCollector_ != address(0), "collector=0");

        items = IGameItemsMintable(items_);
        feeCollector = feeCollector_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RECIPE_ROLE, admin);
    }

    function setFeeCollector(address newFeeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeCollector != address(0), "collector=0");
        feeCollector = newFeeCollector;
    }

    function registerResource(uint256 resourceId, address token) external onlyRole(RECIPE_ROLE) {
        require(token != address(0), "token=0");
        resourceTokenById[resourceId] = token;
        emit ResourceRegistered(resourceId, token);
    }

    function setRecipe(uint256 itemId, uint256 outputAmount, uint256[] calldata packedIngredients)
        external
        onlyRole(RECIPE_ROLE)
    {
        require(outputAmount != 0, "output=0");

        delete _recipeByItem[itemId];
        for (uint256 i = 0; i < packedIngredients.length; ++i) {
            _recipeByItem[itemId].push(packedIngredients[i]);
        }
        outputAmountByItem[itemId] = outputAmount;

        emit RecipeSet(itemId, outputAmount, packedIngredients.length);
    }

    function getRecipe(uint256 itemId) external view returns (uint256[] memory) {
        return _recipeByItem[itemId];
    }

    function craft(uint256 itemId, uint256 batches) external {
        require(batches != 0, "batches=0");

        uint256[] storage recipe = _recipeByItem[itemId];
        uint256 outputAmount = outputAmountByItem[itemId];
        require(recipe.length != 0 && outputAmount != 0, "recipe missing");

        for (uint256 i = 0; i < recipe.length; ++i) {
            (uint128 resourceId, uint128 amount) = RecipeCodec.unpackYul(recipe[i]);
            address token = resourceTokenById[resourceId];
            require(token != address(0), "unknown resource");
            IERC20(token).safeTransferFrom(msg.sender, feeCollector, uint256(amount) * batches);
        }

        items.mint(msg.sender, itemId, outputAmount * batches, "");
        emit Crafted(msg.sender, itemId, outputAmount * batches);
    }
}
