// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {Timelock} from "../src/timelock.sol";
import {GovToken} from "../src/GovToken.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    Timelock timelock;
    GovToken token;

    address public USER = makeAddr("user");
    address public USER_KECIL = makeAddr("user_kecil");
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    //setup dao
    function setUp() public {
        token = new GovToken(); //declare token
        // Kasih USER koin buat vote
        token.transfer(USER, 100 ether); //tf to user,amount 100

        // Kasih USER_KECIL token sedikit (tidak cukup untuk quorum sendiri)
        token.transfer(USER_KECIL, 10 ether);

        // AKTIFIN SUARA: User harus delegate ke diri sendiri
        vm.prank(USER);
        token.delegate(USER);
        vm.prank(USER_KECIL);
        token.delegate(USER_KECIL);
        vm.roll(block.number + 1);

        uint256 minDelay = 3600; // 1 jam

        // empty address - formality
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);

        timelock = new Timelock(minDelay, proposers, executors, address(this));
        governor = new MyGovernor(token, timelock);

        // Setup ijin-ijin (Roles)
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));

        // Serah terima Box ke Timelock
        box = new Box();
        box.transferOwnership(address(timelock));
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888; //store value 888saw
        string memory description = "Ganti angka Box jadi 888 dong!";
        bytes memory data = abi.encodeWithSignature("store(uint256)", valueToStore);

        address[] memory targets = new address[](1);
        targets[0] = address(box);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;

        // 1. PROPOSE (Ngajuin)
        vm.prank(USER);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Lewatin Voting Delay (1 block)
        vm.warp(block.timestamp + 13);
        vm.roll(block.number + 2);

        // 2. VOTE (Milih)
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, 1, "Gw suka angka 8!");

        // Lewatin Voting Period
        vm.roll(block.number + 50401);

        // 3. QUEUE (Masuk Antrian Timelock)
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // Lewatin Timelock Delay (1 jam)
        vm.warp(block.timestamp + 3601);

        // 4. EXECUTE (Jalankan!)
        governor.execute(targets, values, calldatas, descriptionHash);

        // BUKTIKAN: Apakah angkanya beneran ganti jadi 888?
        assertEq(box.getNumber(), 888);
    }

    function testQuorumNotReached() public {
        // 1. PROPOSE
        // proposalThreshold butuh 2 token. USER_KECIL punya 10, jadi aman buat propose.
        uint256 valueToStore = 444;
        string memory description = "Proposal yang bakal gagal quorum";
        bytes memory data = abi.encodeWithSignature("store(uint256)", valueToStore);

        address[] memory targets = new address[](1);
        targets[0] = address(box);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;

        vm.prank(USER_KECIL);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Maju ke masa voting
        vm.warp(block.timestamp + 13);
        vm.roll(block.number + 2);

        // 2. VOTE
        // USER_KECIL cuma punya 10 suara. Quorum butuh 40.
        vm.prank(USER_KECIL);
        governor.castVoteWithReason(proposalId, 1, "Gw cuma punya suara dikit");

        // Lewatin masa voting
        vm.roll(block.number + 50401);

        // 3. QUEUE - HARUSNYA GAGAL
        // State proposal harusnya 'Defeated' karena quorum gak nyampe
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        // Governor bakal revert karena state proposal bukan 'Succeeded'
        vm.expectRevert();
        governor.queue(targets, values, calldatas, descriptionHash);
    }

    function testExecuteTimelockIfTimeIsNotReady() public {
        // setup propose
        uint256 valueToStore = 888;
        string memory description = "change the number to only 888";
        bytes memory data = abi.encodeWithSignature("store(uint256)", valueToStore);

        address[] memory targets = new address[](1);
        targets[0] = address(box);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = data;

        // 1. PROPOSE
        vm.prank(USER);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Maju ke masa voting
        vm.warp(block.timestamp + 13);
        vm.roll(block.number + 2);

        // 2. VOTE
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, 1, "fuck this shit");

        // Lewatin masa voting
        vm.roll(block.number + 50401);

        // 3. QUEUE
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // THE TRAP: We DON'T warp here.
        // Timelock delay is 3600 seconds, but we try to execute immediately.

        // Timelock should revert because operation is not ready
        vm.expectRevert();
        governor.execute(targets, values, calldatas, descriptionHash); // chnge the
    }
}

