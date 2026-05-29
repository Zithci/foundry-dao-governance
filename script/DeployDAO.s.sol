// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/timelock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";

contract DeployDAO is Script {
    //contract instance,save address/identity contract after command new
    Box box;
    GovToken token;
    Timelock timelock;
    MyGovernor governor;

    //constructor params,so contract
    uint256 public constant MIN_DELAY = 3600; // 1 jam
    address[] proposers;
    address[] executors;

    //
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Token
        token = new GovToken();

        // 2. Deploy Timelock (Satpam)
        // Pakai deployerAddress secara eksplisit sebagai admin
        timelock = new Timelock(MIN_DELAY, new address[](0), new address[](0), deployerAddress);

        // 3. Deploy Governor (Otak)
        governor = new MyGovernor(token, timelock);

        // 4. Deploy Box (Target)
        box = new Box();

        // --- Setup Roles ---
        bytes32 proposerRole = timelock.PROPOSER_ROLE(); // propose queque
        bytes32 executorRole = timelock.EXECUTOR_ROLE(); //execute the button when the delay is done
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE(); //the one who can decide who's the proposr/excutor,

        // Governor sebagai proposer ke Timelock
        timelock.grantRole(proposerRole, address(governor));

        // Siapa saja boleh eksekusi (Open Governance)
        timelock.grantRole(executorRole, address(0));

        // Serah terima Box ke Timelock
        box.transferOwnership(address(timelock));

        // Revoke admin dari deployerAddress secara eksplisit
        timelock.revokeRole(adminRole, deployerAddress);

        vm.stopBroadcast();
    }
}
