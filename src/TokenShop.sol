// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AbstractPriceFeed} from "./oracle/chainlink/datafeed/base/AbstractPriceFeed.sol";
import {AbstractToken} from "./token/base/AbstractToken.sol";

contract TokenShop {
    AbstractToken internal immutable token;
    AbstractPriceFeed internal immutable priceFeed;
    address internal owner;

    uint256 internal tokenPrice;
    uint256 internal tokenPriceDecimals;

    uint256 internal constant ETH_DECIMALS = 18; // ETH = 18 decimal places

    event PriceUpdate(address indexed owner, uint256 amountToken);
    event PriceDecimalsUpdate(address indexed owner, uint256 tokenPriceDecimals);

    constructor(
        AbstractToken _tokenAddress,
        AbstractPriceFeed _priceFeed,
        uint256 _tokenPrice,
        uint256 _tokenPriceDecimals
    ) {
        token = AbstractToken(_tokenAddress);
        priceFeed = _priceFeed;
        tokenPrice = _tokenPrice;
        tokenPriceDecimals = _tokenPriceDecimals;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function takeAmount(
        uint256 aceptedTokenAmount
    ) public view returns (uint256) {
        uint256 aceptedTokenPrice = uint256(priceFeed.getChainlinkDataFeedLatestAnswer());
        uint256 amountUsd = aceptedTokenAmount * aceptedTokenPrice;
        uint256 adjustmentFactor = _adjustmentFactor();
        uint256 amountToken = amountUsd / (tokenPrice * 10 ** adjustmentFactor);

        return amountToken;
    }

    function buyTokens() external payable {
        uint256 amountToken = takeAmount(msg.value);
        token.mint(msg.sender, amountToken);

        (bool success,) = address(this).call{value: msg.value}("");
        require(success, "failed to buy tokens");
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    function decimals() public view returns (uint256) {
        return tokenPriceDecimals;
    }

    function setOwner(
        address newOwner
    ) external onlyOwner {
        require(newOwner != address(0), "Cannot set owner to zero");
        owner = newOwner;
    }

    function setTokenPrice(
        uint256 newTokenPrice
    ) external onlyOwner {
        tokenPrice = newTokenPrice;
        emit PriceUpdate(msg.sender, tokenPrice);
    }

    function setTokenPriceDecimals(
        uint256 newTokenPriceDecimals
    ) external onlyOwner {
        tokenPriceDecimals = newTokenPriceDecimals;
        emit PriceDecimalsUpdate(msg.sender, tokenPriceDecimals);
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner);
    }

    function _adjustmentFactor() internal view returns (uint256) {
        return ETH_DECIMALS + priceFeed.decimals() - decimals() - token.decimals();
    }
}
