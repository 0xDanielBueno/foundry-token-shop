// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
        token = new Token("Morsai", "MOR", address(manager));

        // Dá o crachá de MINTER_HOLE para o usuário "mint" (que terá o controle de "mint(address,uint256)").
        manager.grantRole(MINTER_HOLE, mint, 0);
        // Dá o crachá de MINTER_HOLE para o usuário "mint" (que, também, terá o controle de "mint(address,uint256)").
        manager.grantRole(MINTER_HOLE, admin, 0);

        // Cria-se um array de bytes4 (1 unica posição), onde cada bytes4 corresponde ao selector de uma função.
        //   1) Um seletor de função representa os 4 primeiros bytes do hash da função.
        bytes4[] memory selectors = new bytes4[](1);
        // Obtêm-se o selector de "mint(address,uint256)", função ao qual será definida seu controle de acesso.
        selectors[0] = token.transferMintedToken.selector;

        // A partir de agora "Neste contrato (token), a função (mint) só pode ser chamada por quem tem o crachá (MINTER_HOLE)".
        manager.setTargetFunctionRole(address(token), selectors, MINTER_HOLE);

        // Reseta o msg.sender para "TokenTest".
        vm.stopPrank();
    }

    function test_constructor() public {
        vm.expectRevert("Manager cannot be zero address");
        new Token("Morsai", "MOR", address(0));
        vm.expectRevert("Manager should be a authority contract address");
        new Token("Morsai", "MOR", makeAddr("EOA"));
        vm.expectRevert("Name cannot be empty");
        new Token("", "MOR", address(manager));
        vm.expectRevert("Symbol cannot be empty");
        new Token("Morsai", "", address(manager));
    }

    function test_if_authority_is_set() public view {
        assertEq(token.authority(), address(manager));
    }

    function test_if_token_contract_receives_initial_supply() public {
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
    }

    function test_if_mint_token_function_revert_when_called_by_non_onlyowner_owner() public {
        vm.prank(mint);
        vm.expectRevert(
            abi.encodeWithSelector(
                // Seletor de função: "OwnableUnauthorizedAccount(address)"
                Ownable.OwnableUnauthorizedAccount.selector,
                // Parâmetro: "address caller account"
                mint
            )
        );
        token.mint(address(token), 100);
    }

    function test_revert_call_mint_function() public {
        vm.prank(admin);
        vm.expectRevert("To address cannot be zero address");
        token.mint(address(0), 100);
        vm.prank(admin);
        vm.expectRevert("Amount must be greater than zero");
        token.mint(address(token), 0);
    }

    function test_revert_call_transferMintedToken_function() public {
        vm.prank(admin);
        vm.expectRevert("To address cannot be zero address");
        token.transferMintedToken(address(0));
    }

    function test_if_mint_token_function_was_renounced() public {
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                // Seletor de função: "OwnableUnauthorizedAccount(address)"
                Ownable.OwnableUnauthorizedAccount.selector,
                // Parâmetro: "address caller account"
                admin
            )
        );
        token.mint(admin, 100);
    }

    function test_if_minted_token_can_be_transferred() public {
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        address user = makeAddr("EOA");
        vm.prank(admin);
        bool isTransfered = token.transferMintedToken(user);
        assertTrue(isTransfered);
        assertEq(token.balanceOf(user), 100 * 10 ** token.decimals());
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
    }

    function test_if_can_call_transferMintedToken_function_is_set_to_minter_hole() public view {
        (bool isExecuting,) = manager.canCall(mint, address(token), token.transferMintedToken.selector);
        assertTrue(isExecuting);
    }

    function test_revert_if_unauthorized_caller_cannot_call_transferMintedToken_function() public {
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
        token.transferMintedToken(user);
    }

    function test_if_mint_hole_account_can_call_transferMintedToken_function() public {
        address user = makeAddr("EOA");
        (bool isMember,) = manager.hasRole(MINTER_HOLE, mint);
        assertTrue(isMember);
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        vm.prank(mint);
        token.transferMintedToken(user);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(user), 100 * 10 ** token.decimals());
    }

    function test_if_admin_hole_account_can_call_transferMintedToken_function() public {
        address user = makeAddr("EOA");
        (bool isMember,) = manager.hasRole(MINTER_HOLE, admin);
        assertTrue(isMember);
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        vm.prank(admin);
        token.transferMintedToken(user);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(user), 100 * 10 ** token.decimals());
    }

    function test_if_another_account_can_call_transferMintedToken_function() public {
        address user = makeAddr("EOA");
        address anotherUser = makeAddr("ANOTHER_EOA");
        vm.prank(admin);
        manager.grantRole(MINTER_HOLE, anotherUser, 0);
        (bool isMember,) = manager.hasRole(MINTER_HOLE, anotherUser);
        assertTrue(isMember);
        vm.prank(admin);
        token.mint(address(token), 100);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(address(token)), 100 * 10 ** token.decimals());
        vm.prank(anotherUser);
        token.transferMintedToken(user);
        assertEq(token.totalSupply(), 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(user), 100 * 10 ** token.decimals());
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
