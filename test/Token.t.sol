// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

import {Token} from "../src/token/Token.sol";

contract TokenTest is Test {
    address admin = makeAddr("ADMIN_HOLE");
    address mint = makeAddr("MINTER_HOLE");

    AccessManager manager;
    Token token;

    uint64 constant MINTER_HOLE = 1;

    function setUp() public {
        // Muda o msg.sender, temporariamente, de "TokenTest" para "admin".
        vm.startPrank(admin);

        // Cria-se um "livro de Regras" definindo seu administrador.
        manager = new AccessManager(admin);
        // Cria-se o Token e diz: "Siga as regras daquele livro".
        //   1) O "admin" agora controla o Token INDIRETAMENTE.
        //   2) Ele não "fala" com o Token diretamente, e sim com o Manager.
        token = new Token(address(manager));

        // Cria-se um array de bytes4 (1 unica posição), onde cada bytes4 corresponde ao selector de uma função.
        //   1) Um seletor de função representa os 4 primeiros bytes do hash da função.
        bytes4[] memory selectors = new bytes4[](1);
        // Obtêm-se o selector de "mint(address,uint256)", função ao qual será definida seu controle de acesso.
        selectors[0] = token.mint.selector;

        // Dá o crachá de MINTER_HOLE para o usuário "mint" (que terá o controle de "mint(address,uint256)").
        manager.grantRole(MINTER_HOLE, mint, 0);
        // Dá o crachá de MINTER_HOLE para o usuário "mint" (que, também, terá o controle de "mint(address,uint256)").
        manager.grantRole(MINTER_HOLE, admin, 0);
        // A partir de agora "Neste contrato (token), a função (mint) só pode ser chamada por quem tem o crachá (MINTER_HOLE)".
        manager.setTargetFunctionRole(address(token), selectors, MINTER_HOLE);

        // Reseta o msg.sender para "TokenTest".
        vm.stopPrank();
    }

    // function test_if_admin_hole_is_set_to_Admin_address() public view {}

    function test_if_authority_is_set() public view {
        assertEq(token.authority(), address(manager));
    }

    function test_if_can_call_mint_function_is_set_to_minter_hole() public view {
        (bool isExecuting,) = manager.canCall(mint, address(token), token.mint.selector);
        assertTrue(isExecuting);
    }

    function test_revert_if_unauthorized_caller_is_not_minter_hole() public {
        address user = makeAddr("EOA");
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                // Seletor de função: "AccessManagedUnauthorized(address)"
                IAccessManaged.AccessManagedUnauthorized.selector,
                // Parâmetro: "address caller"
                user
            )
        );
        token.mint(user, 100);
    }

    function test_if_mint_hole_call_mint_function() public {
        vm.prank(mint);
        address user = makeAddr("EOA");
        token.mint(user, 100);
        assertEq(token.balanceOf(user), 100);
    }

    function test_if_admin_hole_call_mint_function() public {
        vm.prank(admin);
        address user = makeAddr("EOA");
        token.mint(user, 100);
        assertEq(token.balanceOf(user), 100);
    }

    function test_if_decimals_is_set_correctly() public view {
        assertEq(token.decimals(), 2);
    }

    function test_token_name_is_set_correctly() public view {
        assertEq(token.name(), "Morsai");
    }

    function test_token_symbol_is_set_correctly() public view {
        assertEq(token.symbol(), "MOR");
    }
}
