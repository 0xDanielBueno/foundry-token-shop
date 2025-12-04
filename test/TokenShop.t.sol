// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {TokenShop} from "../src/TokenShop.sol";

import {Token} from "../src/token/Token.sol";
import {PriceFeed} from "../src/oracle/chainlink/datafeed/PriceFeed.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";

import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract TokenShopTest is Test {
    Token token;
    AccessManager manager;
    PriceFeed priceFeed;
    MockV3Aggregator mockAggregator;
    TokenShop tokenShop;

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 302725920800;

    address admin = makeAddr("ADMIN_HOLE");

    function setUp() public {
        vm.startPrank(admin);
        manager = new AccessManager(admin);
        token = new Token("Morsai", "MOR", address(manager));

        mockAggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        priceFeed = new PriceFeed(address(manager), address(mockAggregator));
        tokenShop = new TokenShop(address(manager), address(token), address(priceFeed), 200, 2);

        bytes4[] memory tokenShopSelectors = new bytes4[](4);
        tokenShopSelectors[0] = tokenShop.withdraw.selector;
        tokenShopSelectors[1] = tokenShop.setTokenPrice.selector;
        tokenShopSelectors[2] = tokenShop.setTokenPriceDecimals.selector;
        tokenShopSelectors[3] = tokenShop.setTreasury.selector;

        manager.grantRole(manager.ADMIN_ROLE(), admin, 0);
        manager.setTargetFunctionRole(address(token), tokenShopSelectors, manager.ADMIN_ROLE());
        vm.stopPrank();
    }

    function test_constructor() public {
        vm.expectRevert("Initial authority cannot be zero address");
        new TokenShop(address(0), address(token), address(priceFeed), 200, 2);
        vm.expectRevert("Token address cannot be zero address");
        new TokenShop(address(manager), address(0), address(priceFeed), 200, 2);
        vm.expectRevert("Price feed address cannot be zero address");
        new TokenShop(address(manager), address(token), address(0), 200, 2);
        vm.expectRevert("Token price must be greater than zero");
        new TokenShop(address(manager), address(token), address(priceFeed), 0, 2);
        vm.expectRevert("Token price decimals must be greater than zero");
        new TokenShop(address(manager), address(token), address(priceFeed), 200, 0);
    }

    function test_if_admin_hole_is_setting_to_admin_account() public view {
        (bool isMember,) = manager.hasRole(manager.ADMIN_ROLE(), admin);
        assertTrue(isMember);
    }

    function test_if_admin_hole_can_call_withdraw_function() public view {
        uint64 hole = manager.getTargetFunctionRole(address(token), tokenShop.withdraw.selector);
        assertEq(hole, manager.ADMIN_ROLE());
        (bool isExecuting,) = manager.canCall(admin, address(token), tokenShop.withdraw.selector);
        assertTrue(isExecuting);
    }
}
