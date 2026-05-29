// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_value;
    event ValueChanged(uint256 indexed newValue);
    constructor() Ownable(msg.sender) {}

    function store(uint256 newValue) external onlyOwner {
        s_value = newValue;
        emit ValueChanged(newValue);
    }

    function getNumber() external view returns (uint256) {
        return s_value;
    }
}
