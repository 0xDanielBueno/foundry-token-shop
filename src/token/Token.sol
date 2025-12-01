// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, AccessManaged {
    constructor(
        address _manager
    ) ERC20("Morsai", "MOR") AccessManaged(_manager) {}

    function mint(
        address to,
        uint256 amount
    ) public restricted {
        _mint(to, amount);
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return 2;
    }
}
