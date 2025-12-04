// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {PriceFeed} from "./oracle/chainlink/datafeed/PriceFeed.sol";
import {IToken} from "../src/token/base/IToken.sol";

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenShop is AccessManaged, ReentrancyGuard {
    IToken internal immutable token;
    PriceFeed internal immutable priceFeed;
    address internal immutable manager;

    uint256 internal tokenPrice;
    uint256 internal tokenPriceDecimals;

    address payable internal treasury;

    mapping(address => bool) public whitelistedTreasuries;

    uint256 internal constant ETH_DECIMALS = 18;

    event PriceUpdate(address indexed owner, uint256 amountToken);
    event PriceDecimalsUpdate(address indexed owner, uint256 tokenPriceDecimals);

    constructor(
        address _manager,
        address _tokenAddress,
        address _priceFeed,
        uint256 _tokenPrice,
        uint256 _tokenPriceDecimals
    ) AccessManaged(_manager) {
        require(_manager != address(0), "Initial authority cannot be zero address");
        require(_tokenAddress != address(0), "Token address cannot be zero address");
        require(_priceFeed != address(0), "Price feed address cannot be zero address");
        require(_tokenPrice > 0, "Token price must be greater than zero");
        require(_tokenPriceDecimals > 0, "Token price decimals must be greater than zero");
        manager = _manager;
        treasury = payable(msg.sender);
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

    function buyTokens(
        uint256 aceptedTokenAmount
    ) public payable {
        priceFeed.updatePriceFeed();
        uint256 amountToken = takeAmount(aceptedTokenAmount);
        require(token.totalSuply() >= amountToken, "Not enough tokens");
        token.mint(msg.sender, amountToken);
        (bool success,) = address(this).call{value: aceptedTokenAmount}("");
        require(success, "failed to buy tokens");
    }

    function withdraw() public restricted nonReentrant {
        require(whitelistedTreasuries[treasury], "treasury not whitelisted");
        (bool success,) = treasury.call{value: address(this).balance}("");
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
        address payable newTreasury
    ) public restricted {
        require(newTreasury != address(0), "Treasury cannot be zero address");
        whitelistedTreasuries[newTreasury] = true;
        treasury = newTreasury;
    }

    function _adjustmentFactor() internal view returns (uint256) {
        return ETH_DECIMALS + priceFeed.priceDecimals() - getTokenPriceDecimals() - token.decimals();
    }
}
