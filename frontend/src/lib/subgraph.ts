export const subgraphEndpoint =
  import.meta.env.VITE_SUBGRAPH_URL ?? "https://api.studio.thegraph.com/query/your-subgraph-id/lootforge/version/latest";

export const subgraphQueries = {
  proposals: `
    query ProposalSnapshots {
      proposalSnapshots(first: 5, orderBy: createdAt, orderDirection: desc) {
        id
        proposer
        state
        createdAt
        description
      }
    }
  `,
  swaps: `
    query RecentSwaps {
      swaps(first: 8, orderBy: timestamp, orderDirection: desc) {
        id
        trader
        amountIn
        amountOut
        tokenIn
      }
    }
  `,
};
