// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

import {TokenShop} from "../src/TokenShop.sol";

import {AbstractToken} from "../src/token/base/AbstractToken.sol";
import {Token} from "../src/token/Token.sol";
import {AbstractPriceFeed} from "../src/oracle/chainlink/datafeed/base/AbstractPriceFeed.sol";
import {PriceFeed} from "../src/oracle/chainlink/datafeed/PriceFeed.sol";

contract DeployTokenShop is Script {
    AbstractToken token;
    AbstractPriceFeed priceFeed;
    TokenShop tokenShop;

    function run() external {
        vm.startBroadcast();
        token = new Token();
        /**
         * Price Feed Contract Addresse
         *
         * Network: Sepolia
         * Aggregator: ETH/USD
         * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
         */
        priceFeed = new PriceFeed(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        tokenShop = new TokenShop(token, priceFeed, 200, 2);
        vm.stopBroadcast();
    }
}
