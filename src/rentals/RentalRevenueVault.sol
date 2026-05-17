// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RentalRevenueVault is ERC4626, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant REVENUE_ROLE = keccak256("REVENUE_ROLE");

    event RevenueHarvested(address indexed from, uint256 amount);

    constructor(address asset_, address admin) ERC20("LootForge Revenue Share", "xLFG") ERC4626(IERC20(asset_)) {
        require(admin != address(0), "admin=0");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REVENUE_ROLE, admin);
    }

    function harvestFrom(address from, uint256 amount) external onlyRole(REVENUE_ROLE) {
        require(from != address(0), "from=0");
        require(amount != 0, "amount=0");
        IERC20(asset()).safeTransferFrom(from, address(this), amount);
        emit RevenueHarvested(from, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
