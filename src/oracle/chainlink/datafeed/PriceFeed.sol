// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

contract PriceFeed is AccessManaged {
    AggregatorV3Interface internal immutable dataFeed;

    uint80 public roundIdUpdated;
    int256 public priceUpdated;
    uint256 public priceUpdatedAt;

    uint256 public maxStaleness = 1 hours;

    event PriceFeedUpdated(uint80 indexed newRoundId, int256 indexed newPrice, uint256 indexed newUpdateAt);
    event MaxStalenessUpdated(uint256 indexed newMaxStaleness);

    constructor(
        address _manager,
        address _proxyAggregatorContract
    ) AccessManaged(_manager) {
        require(_manager != address(0), "Initial authority cannot be zero address");
        require(_proxyAggregatorContract != address(0), "Aggregator address cannot be zero address");
        dataFeed = AggregatorV3Interface(_proxyAggregatorContract);
        priceDetails();
    }

    function currentPrice() public view returns (int256 price) {
        return priceUpdated;
    }

    function priceDetails() public {
        (uint80 _roundId, int256 _price,, uint256 _updatedAt,) = dataFeed.latestRoundData();
        roundIdUpdated = _roundId;
        priceUpdated = _price;
        priceUpdatedAt = _updatedAt;
        emit PriceFeedUpdated(roundIdUpdated, priceUpdated, priceUpdatedAt);
    }

    function priceDecimals() public view returns (uint8) {
        return dataFeed.decimals();
    }

    function updatePriceFeed() public restricted {
        if (block.timestamp - priceUpdatedAt >= maxStaleness) {
            priceDetails();
            emit PriceFeedUpdated(roundIdUpdated, priceUpdated, priceUpdatedAt);
        }
    }

    function setMaxStaleness(
        uint256 newMaxStaleness
    ) public restricted {
        maxStaleness = newMaxStaleness;
        emit MaxStalenessUpdated(newMaxStaleness);
    }
}

