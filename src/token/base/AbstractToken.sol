// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

abstract contract AbstractToken {
    function mint(
        address account,
        uint256 amount
    ) external virtual;
    function decimals() external view virtual returns (uint8);
}
