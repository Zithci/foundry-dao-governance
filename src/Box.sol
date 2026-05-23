// SPDX-License-Identif7ier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_value;
    constructor() Ownable(msg.sender) {}

    function store(uint256 newValue) external onlyOwner {
        s_value = newValue;
    }

    function getNumber() external view returns (uint256) {
        return s_value;
    }
}
