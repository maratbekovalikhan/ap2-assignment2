// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {GameGovernor} from "../src/governance/GameGovernor.sol";

contract VerifyDeployment is Script {
    function run() external view {
        TimelockController timelock = TimelockController(payable(vm.envAddress("TIMELOCK")));
        GameGovernor governor = GameGovernor(payable(vm.envAddress("GOVERNOR")));

        require(timelock.getMinDelay() == 2 days, "bad timelock delay");
        require(governor.votingDelay() == 1 days, "bad voting delay");
        require(governor.votingPeriod() == 7 days, "bad voting period");
        require(governor.quorumNumerator() == 4, "bad quorum");

        console2.log("Deployment parameters verified.");
    }
}
