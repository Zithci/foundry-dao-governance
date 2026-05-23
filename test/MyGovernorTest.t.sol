// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function setUp() public {
        token = new GovToken();
        // Kasih USER koin buat vote
        token.transfer(USER, 100 ether);

        // AKTIFIN SUARA: User harus delegate ke diri sendiri
        vm.prank(USER);
        token.delegate(USER);
        vm.roll(block.number + 1);

        uint256 minDelay = 3600; // 1 jam
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
        uint256 valueToStore = 888;
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
        vm.warp(block.timestamp + 13); // Tambah 13 detik
        vm.roll(block.number + 2);    // Maju 2 block biar beneran masuk masa voting

        // 2. VOTE (Milih)
        // 0 = Against, 1 = For, 2 = Abstain
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, 1, "Gw suka angka 8!");

        // Lewatin Voting Period (50400 blocks)
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
}
