// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";

contract BoxTest is Test {
    Box public box;
    address public owner;
    address public user; //fake user

    function setUp() public {
        (owner,) = makeAddrAndKey("owner");
        (user,) = makeAddrAndKey("user");

        //deploy the box
        vm.prank(owner);
        box = new Box();
    }

    function testOnlyOwnerCanStore() public {
        uint256 value = 777; //777 itu apaan?

        //act a& assert
        /* expected to failed  */
        vm.prank(user);
        vm.expectRevert();
        box.store(value);

        //pretend to be bos
        vm.prank(owner);
        box.store(value);
        assertEq(box.getNumber(), value);
    }
}
