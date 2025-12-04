// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, AccessManaged, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _manager
    ) ERC20(_name, _symbol) AccessManaged(_manager) Ownable(msg.sender) {
        require(_manager != address(0), "Manager cannot be zero address");
        require(_manager.code.length > 0, "Manager should be a authority contract address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyOwner {
        require(to != address(0), "To address cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount * 10 ** decimals());
        renounceOwnership();
    }

    function transferMintedToken(
        address to
    ) public restricted returns (bool) {
        require(to != address(0), "To address cannot be zero address");
        _transfer(address(this), to, this.balanceOf(address(this)));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return 2;
    }
}
