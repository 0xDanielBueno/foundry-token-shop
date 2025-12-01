// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";

import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

import {PriceFeed} from "../src/oracle/chainlink/datafeed/PriceFeed.sol";

contract PriceFeedTest is Test {
    address admin = makeAddr("ADMIN_HOLE");

    AccessManager manager;
    PriceFeed priceFeed;
    MockV3Aggregator mockAggregator;

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 302725920800;
    uint256 constant INITIAL_TIMESTAMP = 1000;
    uint80 constant INITIAL_ROUND_ID = 1;

    function setUp() public {
        vm.startPrank(admin);
        manager = new AccessManager(admin);
        mockAggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        priceFeed = new PriceFeed(address(manager), address(mockAggregator));

        bytes4[] memory priceFeedSelectors = new bytes4[](2);
        priceFeedSelectors[0] = priceFeed.updatePriceFeed.selector;
        priceFeedSelectors[1] = priceFeed.setMaxStaleness.selector;

        manager.setTargetFunctionRole(address(priceFeed), priceFeedSelectors, manager.ADMIN_ROLE());
        vm.stopPrank();
    }

    function test_constructor() public {
        assertEq(priceFeed.proxyAggregatorContract(), address(mockAggregator));
        vm.expectRevert("Initial authority cannot be zero address");
        new PriceFeed(address(0), address(mockAggregator));
        vm.expectRevert("Aggregator address cannot be zero address");
        new PriceFeed(address(manager), address(0));
    }

    function test_current_price() public view {
        assertEq(priceFeed.currentPrice(), INITIAL_PRICE);
    }

    function test_current_price_decimals() public view {
        assertEq(priceFeed.priceDecimals(), DECIMALS);
    }

    function test_price_details() public {
        mockAggregator.updateRoundData(INITIAL_ROUND_ID, INITIAL_PRICE, INITIAL_TIMESTAMP, INITIAL_TIMESTAMP);
        vm.expectEmit(true, true, true, true);
        emit PriceFeed.PriceFeedUpdated(INITIAL_ROUND_ID, INITIAL_PRICE, INITIAL_TIMESTAMP);
        priceFeed.priceDetails();
        assertEq(priceFeed.priceUpdated(), INITIAL_PRICE);
        assertEq(priceFeed.priceUpdatedAt(), INITIAL_TIMESTAMP);
        assertEq(priceFeed.roundIdUpdated(), INITIAL_ROUND_ID);
    }

    function test_if_authority_is_set() public view {
        assertEq(priceFeed.authority(), address(manager));
    }

    function test_if_admin_has_hole_admin_role() public view {
        (bool isMember,) = manager.hasRole(manager.ADMIN_ROLE(), admin);
        assertTrue(isMember);
    }

    function test_if_can_call_rtestricted_functions_is_set_to_admin_hole() public view {
        (bool isExecuting,) = manager.canCall(admin, address(priceFeed), priceFeed.updatePriceFeed.selector);
        assertTrue(isExecuting);
    }

    function test_update_price_feed_not_stale() public {
        vm.startPrank(admin);
        uint256 initialTimestamp = block.timestamp;
        mockAggregator.updateRoundData(INITIAL_ROUND_ID, INITIAL_PRICE, initialTimestamp, initialTimestamp);

        uint256 newTimestamp = initialTimestamp + priceFeed.maxStaleness() - 1;
        vm.warp(newTimestamp);
        mockAggregator.updateRoundData(INITIAL_ROUND_ID + 1, INITIAL_PRICE + 100, newTimestamp, newTimestamp);

        priceFeed.updatePriceFeed();
        assertEq(priceFeed.priceUpdatedAt(), initialTimestamp);
        assertEq(priceFeed.priceUpdated(), INITIAL_PRICE);
        assertEq(priceFeed.roundIdUpdated(), INITIAL_ROUND_ID);
        vm.stopPrank();
    }

    function test_update_price_feed_stale() public {
        vm.startPrank(admin);
        uint256 initialTimestamp = block.timestamp;
        mockAggregator.updateRoundData(INITIAL_ROUND_ID, INITIAL_PRICE, initialTimestamp, initialTimestamp);

        uint256 newTimestamp = initialTimestamp + priceFeed.maxStaleness() + 1;
        int256 newPrice = INITIAL_PRICE + 100;
        uint80 newRoundId = INITIAL_ROUND_ID + 1;
        vm.warp(newTimestamp);
        mockAggregator.updateRoundData(newRoundId, newPrice, newTimestamp, newTimestamp);

        vm.expectEmit(true, true, true, true);
        emit PriceFeed.PriceFeedUpdated(newRoundId, newPrice, newTimestamp);

        priceFeed.updatePriceFeed();
        assertEq(priceFeed.priceUpdatedAt(), newTimestamp);
        assertEq(priceFeed.priceUpdated(), newPrice);
        assertEq(priceFeed.roundIdUpdated(), newRoundId);
        vm.stopPrank();
    }

    function test_update_max_staleness() public {
        vm.startPrank(admin);
        uint256 newMaxStaleness = 3 hours;
        priceFeed.setMaxStaleness(newMaxStaleness);
        assertEq(priceFeed.maxStaleness(), newMaxStaleness);
        test_update_price_feed_not_stale();
        test_update_price_feed_stale();
        vm.stopPrank();
    }
}
