// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IToken {
    function mint(
        address account,
        uint256 amount
    ) external;
    function decimals() external view returns (uint8);
}
