// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GameItems1155Upgradeable} from "./GameItems1155Upgradeable.sol";

contract GameItems1155V2 is GameItems1155Upgradeable {
    mapping(uint256 itemId => uint256 cap) private _supplyCaps;

    event SupplyCapSet(uint256 indexed itemId, uint256 cap);

    error SupplyCapExceeded(uint256 itemId, uint256 requested, uint256 cap);

    function setSupplyCap(uint256 itemId, uint256 cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cap == 0 || cap >= totalSupply(itemId), "cap<current");
        _supplyCaps[itemId] = cap;
        emit SupplyCapSet(itemId, cap);
    }

    function supplyCap(uint256 itemId) external view returns (uint256) {
        return _supplyCaps[itemId];
    }

    function version() external pure returns (string memory) {
        return "v2";
    }

    function mint(address to, uint256 id, uint256 amount, bytes calldata data) public override onlyRole(MINTER_ROLE) {
        _enforceCap(id, amount);
        super.mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)
        public
        override
        onlyRole(MINTER_ROLE)
    {
        uint256 length = ids.length;
        require(length == amounts.length, "length mismatch");

        for (uint256 i = 0; i < length; ++i) {
            _enforceCap(ids[i], amounts[i]);
        }

        super.mintBatch(to, ids, amounts, data);
    }

    function _enforceCap(uint256 itemId, uint256 amount) internal view {
        uint256 cap = _supplyCaps[itemId];
        if (cap != 0 && totalSupply(itemId) + amount > cap) {
            revert SupplyCapExceeded(itemId, totalSupply(itemId) + amount, cap);
        }
    }
}
