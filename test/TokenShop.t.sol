// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {TokenShop} from "../src/TokenShop.sol";

import {AbstractToken} from "../src/token/base/AbstractToken.sol";
import {Token} from "../src/token/Token.sol";
import {AbstractPriceFeed} from "../src/oracle/chainlink/datafeed/base/AbstractPriceFeed.sol";
import {PriceFeed} from "../src/oracle/chainlink/datafeed/PriceFeed.sol";

contract TokenShopTest is Test {
    AbstractToken token;
    AbstractPriceFeed ethUsdPriceFeed;
    TokenShop tokenShop;

    function setUp() public {
        token = new Token();
        /**
         * Price Feed Contract Addresse
         *
         * Network: Sepolia
         * Aggregator: ETH/USD
         * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
         */
        ethUsdPriceFeed = new PriceFeed(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        tokenShop = new TokenShop(token, ethUsdPriceFeed, 200, 2);
    }

    function test_if_take_amount_is_correct() public view {
        uint256 amountEth = 0.01 ether;
        uint256 amountToken = tokenShop.takeAmount(amountEth);
        assert(amountToken > 0);
        console.log("Amount Token:", amountToken);
    }

    function test_if_decimals_of_my_token_is_2() public view {
        uint8 decimals = token.decimals();
        assertEq(token.decimals(), decimals);
        console.log("Decimals:", decimals);
    }
}
