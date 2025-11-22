// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

abstract contract AbstractPriceFeed {
    AggregatorV3Interface internal immutable dataFeed;

    constructor(
        address _aggregatorAddress
    ) {
        dataFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (, int256 answer,,,) = dataFeed.latestRoundData();
        return answer;
    }

    function decimals() public view returns (uint8) {
        return dataFeed.decimals();
    }
}

