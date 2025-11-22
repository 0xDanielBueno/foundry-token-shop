// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AbstractPriceFeed} from "./base/AbstractPriceFeed.sol";

contract PriceFeed is AbstractPriceFeed {
    constructor(
        address _aggregatorAddress
    ) AbstractPriceFeed(_aggregatorAddress) {}
}
