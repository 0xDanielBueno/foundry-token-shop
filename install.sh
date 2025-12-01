forge init .

forge install smartcontractkit/chainlink-brownie-contracts

forge install OpenZeppelin/openzeppelin-contracts

forge remappings > remappings.txt

cast wallet import ethsepoliakey --interactive

cast wallet list

forge script script/DeployTokenShop.s.sol

forge script script/DeployTokenShop.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --account ethsepoliakey \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --broadcast \
    --slow \
    -vvvv

forge verify-contract 0x31D3AA9B85b05719a96C3A008a544bBe8231753b \
    --rpc-url $SEPOLIA_RPC_URL \
    -vvvv

forge verify-contract 0x6df8A342CC012486363300e3daFBF0c91B3Cc4c6 \
    --rpc-url $SEPOLIA_RPC_URL \
    -vvvv

forge verify-contract 0x233C30939B11561326006D8317976Dbbf6176B45 \
    --rpc-url $SEPOLIA_RPC_URL \
    -vvvv


# Mint 100 tokens to address EOA (Externally Owned Account)
cast send $TOKEN_CONTRACT_ADDRESS \
    --rpc-url $SEPOLIA_RPC_URL \
    --account ethsepoliakey \
    "mint(address,uint256)" 0x4afa2412068684e7e8458944670b2fe78e447cfb 10000 \
    -vvvv

# Check balance of address
cast call $TOKEN_CONTRACT_ADDRESS \
    --rpc-url $SEPOLIA_RPC_URL \
    "balanceOf(address)" 0x4afa2412068684e7e8458944670b2fe78e447cfb \
    -vvvv

# Print balance of address as dec
cast --to-base 0x0000000000000000000000000000000000000000000000000000000000002710 dec

cast send $TOKEN_CONTRACT_ADDRESS \
    --rpc-url $SEPOLIA_RPC_URL \
    --account ethsepoliakey \
    "grantRole(role,account)" 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6 10000 \
    -vvvv

forge test --mt test_if_take_amount_is_correct \
    --fork-url $SEPOLIA_RPC_URL \
    -vvvv

forge test --mt test_if_decimals_of_my_token_is_2 \
    -vvvv

forge test \
    --fork-url $SEPOLIA_RPC_URL \
    -vvvv

forge coverage \
    --fork-url $SEPOLIA_RPC_URL \
    --report lcov \
    --report-file lcov.info \
    -vvvv

genhtml -o report --no-branch-coverage lcov.info

cast sig "mint(address,uint256)"

cast kecca256 "mint(address,uint256)"

forge test \
    --mt test_if_minter_hole_is_executing_token_mint \
    -vvvv


forge test \
    --mp test/Token.t.sol \
    -vvvv

forge coverage \
    --mp test/Token.t.sol \
    --report lcov \
    --report-file lcov.info \
    -vvvv

forge test \
    --mp test/PriceFeed.t.sol \
    -vvvv

forge coverage \
    --mp test/PriceFeed.t.sol \
    --report lcov \
    --report-file lcov.info \
    -vvvv

forge test \
    --mp test/TokenShop.t.sol \
    -vvvv

forge test -vvvvv

forge coverage \
    --report lcov \
    --report-file lcov.info \
    -vvvvv