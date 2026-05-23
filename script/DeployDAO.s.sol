// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Box} from "../src/Box.sol";
import {GovToken} from "../src/GovToken.sol";
import {Timelock} from "../src/timelock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";

contract DeployDAO is Script {
    Box box;
    GovToken token;
    Timelock timelock;
    MyGovernor governor;

    uint256 public constant MIN_DELAY = 3600; // 1 jam
    address[] proposers;
    address[] executors;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Token
        token = new GovToken();

        // 2. Deploy Timelock (Satpam)
        // Admin sementara adalah deployer buat setup roles
        timelock = new Timelock(MIN_DELAY, new address[](0), new address[](0), msg.sender);

        // 3. Deploy Governor (Otak)
        governor = new MyGovernor(token, timelock);

        // 4. Deploy Box (Target)
        box = new Box();

        // --- Setup Roles ---
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        // Governor sebagai proposer ke Timelock
        timelock.grantRole(proposerRole, address(governor));

        // Siapa saja boleh eksekusi (Open Governance)
        timelock.grantRole(executorRole, address(0));

        // Serah terima Box ke Timelock
        box.transferOwnership(address(timelock));

        // PENTING: Revoke admin dari deployer supaya DAO terdesentralisasi
        // Sekarang cuma Timelock (DAO) yang bisa manage dirinya sendiri
        timelock.revokeRole(adminRole, msg.sender);

        vm.stopBroadcast();
    }
}
