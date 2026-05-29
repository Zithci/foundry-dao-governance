// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers, //bout to be filled with governor adderss
        address[] memory executors, //
        address admin //whos  have the access tochange the settings of the timelock
    )
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
