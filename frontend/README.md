# LootForge Frontend

This app is the root-level frontend shell for the LootForge protocol.

## Current State

- Vite + React scaffold
- protocol dashboard layout
- sections for governance, AMM, crafting, rentals, and indexed data
- environment-based contract address configuration
- subgraph endpoint wiring scaffold

## Next Integration Steps

1. Install dependencies with `npm install`.
2. Copy `.env.example` to `.env`.
3. Replace placeholder contract addresses with deployed L2 addresses.
4. Add Wagmi config and wallet connectors.
5. Replace mock cards with live contract reads and subgraph queries.

## Planned Reads

- governance token balance
- voting power
- delegate address
- active proposals and their states
- AMM reserves
- recipe outputs and costs
- hero rental listings

## Planned Writes

- `swap`
- `craft`
- `vote`
- `rentHero`
