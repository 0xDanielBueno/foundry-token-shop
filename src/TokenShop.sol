// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {PriceFeed} from "./oracle/chainlink/datafeed/PriceFeed.sol";
import {IToken} from "../src/token/base/IToken.sol";

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

contract TokenShop is AccessManaged {
    IToken internal immutable token;
    PriceFeed internal immutable priceFeed;

    uint256 internal tokenPrice;
    uint256 internal tokenPriceDecimals;

    uint256 internal constant ETH_DECIMALS = 18;

    address internal immutable manager;
    address internal treasury;

    event PriceUpdate(address indexed owner, uint256 amountToken);
    event PriceDecimalsUpdate(address indexed owner, uint256 tokenPriceDecimals);

    constructor(
        address _manager,
        address _newTreasury,
        address _tokenAddress,
        address _priceFeed,
        uint256 _tokenPrice,
        uint256 _tokenPriceDecimals
    ) AccessManaged(_manager) {
        require(_manager != address(0), "Initial authority cannot be zero address");
        require(_newTreasury != address(0), "Treasury cannot be zero address");
        require(_tokenAddress != address(0), "Token address cannot be zero address");
        manager = _manager;
        treasury = _newTreasury;
        token = IToken(_tokenAddress);
        priceFeed = PriceFeed(_priceFeed);
        tokenPrice = _tokenPrice;
        tokenPriceDecimals = _tokenPriceDecimals;
    }

    function takeAmount(
        uint256 aceptedTokenAmount
    ) public view returns (uint256) {
        uint256 aceptedTokenPrice = uint256(priceFeed.currentPrice());
        uint256 amountUsd = aceptedTokenAmount * aceptedTokenPrice;
        uint256 adjustmentFactor = _adjustmentFactor();
        uint256 amountToken = amountUsd / (tokenPrice * 10 ** adjustmentFactor);
        return amountToken;
    }

    function buyTokens() public payable {
        priceFeed.updatePriceFeed();
        uint256 amountToken = takeAmount(msg.value);
        token.mint(msg.sender, amountToken);
        (bool success,) = address(this).call{value: msg.value}("");
        require(success, "failed to buy tokens");
    }

    function withdraw() public restricted {
        (bool success,) = payable(treasury).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    function getTokenPriceDecimals() public view returns (uint256) {
        return tokenPriceDecimals;
    }

    function setTokenPrice(
        uint256 newTokenPrice
    ) public restricted {
        tokenPrice = newTokenPrice;
        emit PriceUpdate(manager, tokenPrice);
    }

    function setTokenPriceDecimals(
        uint256 newTokenPriceDecimals
    ) public restricted {
        tokenPriceDecimals = newTokenPriceDecimals;
        emit PriceDecimalsUpdate(manager, tokenPriceDecimals);
    }

    function setTreasury(
        address newTreasury
    ) public restricted {
        require(newTreasury != address(0), "Treasury cannot be zero address");
        treasury = newTreasury;
    }

    function _adjustmentFactor() internal view returns (uint256) {
        return ETH_DECIMALS + priceFeed.priceDecimals() - getTokenPriceDecimals() - token.decimals();
    }
}
