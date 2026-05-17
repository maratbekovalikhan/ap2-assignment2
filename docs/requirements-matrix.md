# Requirements Matrix

## Option B Mapping

| Rubric requirement | LootForge component |
| --- | --- |
| ERC-1155 item economy | `GameItems1155Upgradeable` |
| Crafting | `CraftingStation` |
| Marketplace AMM | `ResourcePair` + `ResourceFactory` |
| NFT rental vault | `HeroNFT` + `HeroRentalVault` |
| Chainlink VRF loot drops | `LootDropManager` |
| DAO-governed parameters | `GameGovernor` + `TimelockController` + role-gated setters |
| L2 deployment | `script/DeployLocal.s.sol` to be extended to Base/Arbitrum/Optimism Sepolia |

## Mandatory Course Components

| Course requirement | Planned implementation |
| --- | --- |
| UUPS upgradeability | `GameItems1155Upgradeable` -> `GameItems1155V2` |
| Factory with `CREATE` and `CREATE2` | `ResourceFactory` deploys resources with `CREATE` and pairs with `CREATE2` |
| Inline Yul benchmark | `RecipeCodec` packs recipe entries with Yul and pure Solidity equivalents |
| Governance token `ERC20Votes` + `ERC20Permit` | `GameGovernanceToken` |
| ERC-721 or ERC-1155 | both `HeroNFT` and `GameItems1155Upgradeable` |
| ERC-4626 vault | `RentalRevenueVault` |
| DeFi primitive built from scratch | `ResourcePair` constant-product AMM with 0.3% fee |
| Chainlink price feed with staleness check | `PriceOracleAdapter` |
| Mock aggregator for tests | `MockV3Aggregator` |
| Subgraph with 4+ entities | `HeroRental`, `Swap`, `LiquidityPosition`, `CraftEvent`, `ProposalSnapshot`, `LootDrop` |
| Governor + Timelock | `GameGovernor` + `TimelockController` |
| 2-day timelock delay | deploy config |
| L2 gas comparison | benchmark report after deployment |

## Design Patterns Already Selected

- Factory
- UUPS Proxy
- Checks-Effects-Interactions
- Role-based Access Control
- Pausable / Circuit Breaker
- Timelock Governance
- Reentrancy Guard
- Oracle Adapter

## Security Deliverables To Produce

- Reentrancy case study with before/after tests
- Access-control case study with before/after tests
- Slither clean report with documented low/info findings
- Centralization analysis for all admin and timelock powers
