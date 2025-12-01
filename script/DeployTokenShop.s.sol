// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

import {TokenShop} from "../src/TokenShop.sol";

import {Token} from "../src/token/Token.sol";
import {PriceFeed} from "../src/oracle/chainlink/datafeed/PriceFeed.sol";

import {AccessManager} from "@openzeppelin/contracts/access/manager/AccessManager.sol";

contract DeployTokenShop is Script {
    Token token;
    PriceFeed priceFeed;
    AccessManager manager;
    TokenShop tokenShop;

    uint64 constant MINTER_ROLE = 1;

    function run() external {
        vm.startBroadcast();
        // Cria-se um "livro de Regras" definindo seu administrador.
        manager = new AccessManager(msg.sender);
        // Cria-se o Token e diz: "Siga as regras daquele livro".
        //   1) O "admin" agora controla o Token INDIRETAMENTE.
        //   2) Ele não "fala" com o Token diretamente, e sim com o Manager.
        token = new Token(address(manager));

        // Cria-se um array de bytes4 (2 posições), onde cada bytes4 corresponde ao selector de uma função.
        //   1) Um seletor de função representa os 4 primeiros bytes do hash da função.
        //   2) O array tem 2 posições, pois temos 2 funções no contrato PriceFeed marcadas como "restricted".
        bytes4[] memory priceFeedSelectors = new bytes4[](2);
        // Obtêm-se o selector de "updatePriceFeed()", função ao qual será definida seu controle de acesso.
        priceFeedSelectors[0] = priceFeed.updatePriceFeed.selector;
        // Obtêm-se o selector de "setMaxStaleness(uint256)", função ao qual será definida seu controle de acesso.
        priceFeedSelectors[1] = priceFeed.setMaxStaleness.selector;

        // Cria-se um selector de função para o contrato Token.
        bytes4[] memory tokenSelectors = new bytes4[](1);
        // Obtêm-se o selector de "mint(address,uint256)", função ao qual será definida seu controle de acesso.
        tokenSelectors[0] = token.mint.selector;

        // Dá o crachá de MINTER_HOLE para o usuário "msg.sender" (que terá o controle de "mint(address,uint256)").
        manager.grantRole(MINTER_ROLE, msg.sender, 0);

        // Dá o crachá de ADMIN_ROLE para o usuário "msg.sender" (que terá o controle de tudo).
        manager.grantRole(manager.ADMIN_ROLE(), msg.sender, 0);

        // A partir de agora "Neste contrato (token), a função (mint) só pode ser chamada por quem tem o crachá (MINTER_HOLE)".
        manager.setTargetFunctionRole(address(token), tokenSelectors, MINTER_ROLE);

        // A partir de agora "Neste contrato (priceFeed), a função (updatePriceFeed e setMaxStaleness) só pode ser chamada por
        // quem tem o crachá (ADMIN_ROLE)".
        manager.setTargetFunctionRole(address(priceFeed), priceFeedSelectors, manager.ADMIN_ROLE());

        /**
         * Price Feed Contract Addresse
         *
         * Network: Sepolia
         * Aggregator: ETH/USD
         * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
         */
        priceFeed = new PriceFeed(address(manager), 0x694AA1769357215DE4FAC081bf1f309aDC325306);
        tokenShop = new TokenShop(address(manager), msg.sender, address(token), address(priceFeed), 200, 2);
        vm.stopBroadcast();
    }
}
