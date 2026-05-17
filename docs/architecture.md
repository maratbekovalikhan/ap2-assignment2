# Architecture Snapshot

## Protocol Story

Players acquire fungible resources such as `GOLD`, `WOOD`, and `CRYSTAL`, trade them in the AMM, and consume them in `CraftingStation` recipes to mint `ERC-1155` game items. High-value hero NFTs are deposited into `HeroRentalVault`, where renters pay fees in a fungible token while posting oracle-priced collateral. Loot drops are distributed through Chainlink VRF so that rare item assignment is verifiable on-chain. Governance token holders propose and vote on changes to recipes, loot tables, fee policies, and privileged roles through an OZ Governor + Timelock stack.

## Contract Map

- `GameGovernanceToken`: timestamp-based votes token with permit support
- `GameGovernor`: DAO with 1 day voting delay, 1 week voting period, 4% quorum, 1% proposal threshold
- `TimelockController`: 2 day delay, final admin over treasury-like components
- `GameItems1155Upgradeable`: upgradeable item contract, minter-gated
- `GameItems1155V2`: adds optional per-item supply caps
- `HeroNFT`: rentable hero collection
- `ResourceFactory`: deterministic pair deployment and resource mintable token deployment
- `ResourcePair`: fee-charging CPMM with LP accounting
- `CraftingStation`: recipe storage, resource spending, item minting
- `PriceOracleAdapter`: stale-price rejection and USD quote normalization
- `HeroRentalVault`: hero custody, rental rights, collateral settlement
- `RentalRevenueVault`: ERC-4626 fee sink and revenue-sharing vault
- `LootDropManager`: VRF request/fulfillment and weighted drop selection

## Critical Flows

### Crafting

1. DAO approves resource registrations and recipe updates.
2. Player approves resource tokens to `CraftingStation`.
3. `CraftingStation` transfers recipe costs and mints the target ERC-1155 item.

### AMM Trade

1. LP seeds a `ResourcePair` through the factory.
2. Trader calls `swap` with `amountOutMin`.
3. Pair applies 0.3% fee and updates reserves.

### Governance

1. Token holder delegates votes to self.
2. Proposal is created in `GameGovernor`.
3. Voting runs for one week after a one-day delay.
4. Successful proposal is queued in the timelock for two days.
5. Timelock executes the parameter change on the target contract.

### Rental

1. Hero owner deposits an NFT into `HeroRentalVault` and defines rental terms.
2. Renter pays fee assets and posts native collateral validated by the oracle.
3. Vault marks the renter as the active in-game user until expiry.
4. Rental is closed normally or collateral is slashed on overdue settlement.

## Storage / Upgrade Notes

- `GameItems1155Upgradeable` is the upgradeable surface.
- V2 appends new storage for `supplyCap` mappings, avoiding slot collisions by only appending state.
- Governance token is timestamp-based so governance windows are expressed in seconds rather than rough block estimates.

## Recommended Build Order

1. Get contracts compiling and tested locally.
2. Finish AMM + crafting path first.
3. Add governor/timelock and role handoff.
4. Add oracle + rental vault.
5. Add VRF and subgraph.
6. Wire frontend and L2 deployment.
