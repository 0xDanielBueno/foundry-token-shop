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

    uint64 constant MINTER_ROLE = 1;

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 302725920800;
    // uint256 constant INITIAL_TIMESTAMP = 1000;
    // uint80 constant INITIAL_ROUND_ID = 1;

    address minterHole = makeAddr("MINTER_HOLE");
    address adminHole = makeAddr("ADMIN_HOLE");

    function setUp() public {
        // Muda o msg.sender, temporariamente, de "TokenTest" para "adminHole".
        vm.startPrank(adminHole);
        // Cria-se um "livro de Regras" definindo seu administrador.
        manager = new AccessManager(adminHole);
        // Cria-se o Token e diz: "Siga as regras daquele livro".
        //   1) O "admin" agora controla o Token INDIRETAMENTE.
        //   2) Ele não "fala" com o Token diretamente, e sim com o Manager.
        token = new Token(address(manager));

        mockAggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        priceFeed = new PriceFeed(address(manager), address(mockAggregator));
        tokenShop = new TokenShop(address(manager), adminHole, address(token), address(priceFeed), 200, 2);

        bytes4[] memory tokenSelectors = new bytes4[](1);
        tokenSelectors[0] = token.mint.selector;

        manager.grantRole(MINTER_ROLE, minterHole, 0);
        manager.setTargetFunctionRole(address(token), tokenSelectors, MINTER_ROLE);
        vm.stopPrank();
    }

    function test_if_minter_hole_is_executing_token_mint() public view {
        (bool isExecuting,) = manager.canCall(minterHole, address(token), token.mint.selector);
        assertTrue(isExecuting);
    }

    function test_if_admin_hole_is_setting_to_contract_admin() public view {
        (bool isMember,) = manager.hasRole(manager.ADMIN_ROLE(), adminHole);
        assertTrue(isMember);
    }

    function test_if_function_mint_hole_is_setting_minter_role() public view {
        uint64 hole = manager.getTargetFunctionRole(address(token), token.mint.selector);
        assertEq(hole, MINTER_ROLE);
    }
}
