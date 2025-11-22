// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AbstractToken} from "./base/AbstractToken.sol";

contract Token is ERC20, AccessControl, AbstractToken {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Morsai", "MOR") {
        require(_grantRole(DEFAULT_ADMIN_ROLE, msg.sender), "Failed to grant admin role");
        require(_grantRole(MINTER_ROLE, msg.sender), "Failed to grant minter role");
    }

    function mint(
        address to,
        uint256 amount
    ) public override(AbstractToken) onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function minterHole() public pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function decimals() public pure override(ERC20, AbstractToken) returns (uint8) {
        return 2;
    }
}
