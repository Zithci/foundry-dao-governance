// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//importing ingridients
import {Script} from "forge-std/Script.sol"; //vm start broadcast and other utilities

//availble for the scope
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/timelock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";

contract deploydao is Script {}
