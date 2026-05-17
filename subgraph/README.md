# LootForge Subgraph

This directory contains the indexing scaffold for LootForge protocol activity.

## Indexed Domains

- `ResourcePair`: AMM reserves, swaps, liquidity activity
- `CraftingStation`: crafting events and recipe-driven usage
- `HeroRentalVault`: rental lifecycle and hero listing state
- `LootDropManager`: VRF-backed loot fulfillment history
- `GameGovernor`: proposal lifecycle snapshots and voting analytics

## Planned Entities

- `ResourcePair`
- `LiquidityPosition`
- `Swap`
- `CraftEvent`
- `HeroRental`
- `LootDrop`
- `ProposalSnapshot`
- `VoteRecord`

## Deployment Steps

1. Replace zero addresses in `subgraph.yaml` with deployed contract addresses.
2. Export ABIs from the Foundry build artifacts into `subgraph/abis/`.
3. Run `graph codegen`.
4. Run `graph build`.
5. Deploy to The Graph Studio or hosted service target.

## Query Pack

Documented GraphQL queries live in [queries.graphql](/Users/arslanmaratbekov/Documents/New project/subgraph/queries.graphql).
