# LootForge Protocol

LootForge is our **Blockchain Technologies 2 Final Project** for **Option B - GameFi Economy**.

The protocol combines all required domains from the course into one production-style decentralized system:

- `ERC-1155` in-game item economy
- crafting with on-chain recipes
- constant-product AMM for fungible resources
- `ERC-721` hero NFT rental vault
- Chainlink VRF loot drops
- DAO governance over gameplay and protocol parameters
- L2-oriented deployment pipeline

## Team

- **Alikhan Maratbekov**
- **Miras Khaval**
- **Nurassyl Mukhtaruly**

Detailed ownership is documented in [docs/team-ownership.md](/Users/arslanmaratbekov/Documents/New project/docs/team-ownership.md).

## Repository Layout

```text
src/        Solidity contracts
test/       Foundry tests
script/     deployment, upgrade, verification scripts
frontend/   React + Wagmi/Viem dApp scaffold
subgraph/   The Graph scaffold
docs/       architecture, requirement mapping, ownership docs
lib/        Foundry dependencies
```

## Core Smart Contracts

- [src/core/GameGovernanceToken.sol](/Users/arslanmaratbekov/Documents/New project/src/core/GameGovernanceToken.sol): `ERC20Votes` + `ERC20Permit`
- [src/core/GameItems1155Upgradeable.sol](/Users/arslanmaratbekov/Documents/New project/src/core/GameItems1155Upgradeable.sol): upgradeable `ERC-1155`
- [src/core/GameItems1155V2.sol](/Users/arslanmaratbekov/Documents/New project/src/core/GameItems1155V2.sol): documented V1 -> V2 upgrade path
- [src/core/HeroNFT.sol](/Users/arslanmaratbekov/Documents/New project/src/core/HeroNFT.sol): rentable hero NFT collection
- [src/amm/ResourceFactory.sol](/Users/arslanmaratbekov/Documents/New project/src/amm/ResourceFactory.sol): `CREATE` + `CREATE2` factory
- [src/amm/ResourcePair.sol](/Users/arslanmaratbekov/Documents/New project/src/amm/ResourcePair.sol): constant-product AMM with 0.3% fee
- [src/crafting/CraftingStation.sol](/Users/arslanmaratbekov/Documents/New project/src/crafting/CraftingStation.sol): recipe registry and crafting execution
- [src/rentals/HeroRentalVault.sol](/Users/arslanmaratbekov/Documents/New project/src/rentals/HeroRentalVault.sol): NFT custody and rental lifecycle
- [src/rentals/RentalRevenueVault.sol](/Users/arslanmaratbekov/Documents/New project/src/rentals/RentalRevenueVault.sol): `ERC-4626` rental revenue vault
- [src/loot/LootDropManager.sol](/Users/arslanmaratbekov/Documents/New project/src/loot/LootDropManager.sol): Chainlink VRF loot distribution
- [src/governance/GameGovernor.sol](/Users/arslanmaratbekov/Documents/New project/src/governance/GameGovernor.sol): OZ Governor + Timelock stack
- [src/oracle/PriceOracleAdapter.sol](/Users/arslanmaratbekov/Documents/New project/src/oracle/PriceOracleAdapter.sol): stale-price-protected Chainlink adapter

## Requirement Coverage

The rubric mapping lives in [docs/requirements-matrix.md](/Users/arslanmaratbekov/Documents/New project/docs/requirements-matrix.md).

The current architecture summary lives in [docs/architecture.md](/Users/arslanmaratbekov/Documents/New project/docs/architecture.md).

## Local Commands

```bash
forge build
forge test --offline --suppress-successful-traces
forge fmt --check
```

## Current Status

Already implemented in the repository:

- root-level Foundry project scaffold
- starter GameFi contract system
- upgradeable contract path
- governance/token foundation
- AMM foundation
- oracle adapter
- VRF loot manager scaffold
- rental vault scaffold
- CI workflow for contracts + Slither
- initial passing test suite

## Next Milestones

1. Expand tests to hit the full course minimums: unit, fuzz, invariant, fork.
2. Complete governance lifecycle tests: propose -> vote -> queue -> execute.
3. Finish frontend wallet, governance, AMM, crafting, and rental flows.
4. Complete subgraph mappings and GraphQL query examples.
5. Deploy and verify on an L2 testnet.
6. Produce audit, gas, and architecture reports for submission.

## Note

Some older coursework files are still present in this repository, but the active final project for this capstone is now the LootForge blockchain stack described above.
