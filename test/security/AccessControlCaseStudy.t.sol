// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract VulnerableConfig {
    uint256 public marketplaceFeeBps;

    function setMarketplaceFeeBps(uint256 newFeeBps) external {
        marketplaceFeeBps = newFeeBps;
    }
}

contract FixedConfig is AccessControl {
    bytes32 public constant PARAM_ROLE = keccak256("PARAM_ROLE");
    uint256 public marketplaceFeeBps;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PARAM_ROLE, admin);
    }

    function setMarketplaceFeeBps(uint256 newFeeBps) external onlyRole(PARAM_ROLE) {
        marketplaceFeeBps = newFeeBps;
    }
}

contract AccessControlCaseStudyTest is Test {
    VulnerableConfig internal vulnerable;
    FixedConfig internal fixedConfig;
    address internal attacker = address(0xBAD);

    function setUp() external {
        vulnerable = new VulnerableConfig();
        fixedConfig = new FixedConfig(address(this));
    }

    function test_anyUserCanMutateVulnerableConfig() external {
        vm.prank(attacker);
        vulnerable.setMarketplaceFeeBps(9_999);

        assertEq(vulnerable.marketplaceFeeBps(), 9_999);
    }

    function test_fixedConfigRejectsUnauthorizedCaller() external {
        vm.prank(attacker);
        vm.expectRevert();
        fixedConfig.setMarketplaceFeeBps(9_999);
    }
}
