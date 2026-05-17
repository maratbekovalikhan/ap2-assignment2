import { contractAddresses, targetNetwork } from "./lib/contracts";
import { subgraphEndpoint, subgraphQueries } from "./lib/subgraph";

type ProposalCard = {
  id: string;
  title: string;
  state: "Pending" | "Active" | "Succeeded" | "Queued" | "Executed";
  summary: string;
  quorum: string;
};

type PoolCard = {
  name: string;
  reserves: string;
  volume: string;
  fee: string;
};

type RecipeCard = {
  item: string;
  output: string;
  ingredients: string;
};

type RentalCard = {
  hero: string;
  owner: string;
  fee: string;
  collateral: string;
  status: "Open" | "Rented" | "Overdue";
};

const proposals: ProposalCard[] = [
  {
    id: "#17",
    title: "Lower epic sword crystal cost by 8%",
    state: "Active",
    summary: "Adjust the sword recipe after observing low mint throughput on Base Sepolia.",
    quorum: "4% quorum / 1 week voting",
  },
  {
    id: "#16",
    title: "Route crafting fees to the DAO-controlled revenue vault",
    state: "Queued",
    summary: "Moves crafting proceeds into the treasury pipeline governed by the timelock.",
    quorum: "Queued in timelock",
  },
  {
    id: "#15",
    title: "Increase rare chest loot weight for Ranger shards",
    state: "Executed",
    summary: "Gameplay balance update after beta test data showed shard scarcity.",
    quorum: "Executed after delay",
  },
];

const pools: PoolCard[] = [
  { name: "GLD / WOOD", reserves: "125,420 GLD / 91,200 WOOD", volume: "$18.4k", fee: "0.3%" },
  { name: "GLD / CRYSTAL", reserves: "88,010 GLD / 14,560 CRYSTAL", volume: "$25.9k", fee: "0.3%" },
];

const recipes: RecipeCard[] = [
  { item: "Epic Sword", output: "1 item", ingredients: "120 GLD + 12 CRYSTAL" },
  { item: "Healing Potion", output: "3 items", ingredients: "18 GLD + 6 HERB" },
  { item: "Guardian Shield", output: "1 item", ingredients: "70 GLD + 24 WOOD" },
];

const rentals: RentalCard[] = [
  { hero: "Sentinel #12", owner: "0xA11C...b2F3", fee: "25 GLD / day", collateral: "500 USD", status: "Open" },
  { hero: "Ranger #3", owner: "0x91f1...19B4", fee: "40 GLD / day", collateral: "750 USD", status: "Rented" },
  { hero: "Mage #8", owner: "0x77de...A911", fee: "55 GLD / day", collateral: "900 USD", status: "Overdue" },
];

const protocolMetrics = [
  { label: "Target L2", value: targetNetwork, note: "Final deployment network" },
  { label: "Governor Delay", value: "1 day", note: "Voting delay" },
  { label: "Timelock", value: "2 days", note: "Execution buffer" },
  { label: "Test Coverage", value: "39 tests", note: "Unit + fuzz + invariant" },
];

function statePillClass(state: ProposalCard["state"] | RentalCard["status"]) {
  if (state === "Executed" || state === "Open") return "pill";
  if (state === "Queued" || state === "Rented") return "pill warning";
  if (state === "Overdue") return "pill danger";
  return "pill";
}

export function App() {
  return (
    <main className="app-shell">
      <section className="hero">
        <article className="card">
          <div className="eyebrow">Blockchain Technologies 2 • Option B</div>
          <h1 className="hero-title">LootForge GameFi Economy</h1>
          <p className="hero-copy">
            A GameFi capstone combining ERC-1155 item crafting, a constant-product AMM, hero NFT rentals,
            Chainlink-powered loot drops, and DAO governance over gameplay parameters on an L2-first stack.
          </p>
          <div className="hero-actions">
            <button className="button-primary">Connect MetaMask</button>
            <button className="button-secondary">Switch to {targetNetwork}</button>
          </div>
        </article>

        <aside className="card wallet-card">
          <div>
            <div className="section-kicker">Wallet Status</div>
            <h2 className="section-title">Connection scaffold ready</h2>
            <p className="hero-copy">
              This app shell is prepared for Wagmi/Viem integration. The next step is wiring real contract reads
              and writes against the deployed governor, vaults, and AMM pairs.
            </p>
          </div>

          <div className="address-list">
            <div className="address-item">
              <div className="tiny">Governor</div>
              <div className="code-block">{contractAddresses.governor}</div>
            </div>
            <div className="address-item">
              <div className="tiny">Crafting Station</div>
              <div className="code-block">{contractAddresses.craftingStation}</div>
            </div>
            <div className="address-item">
              <div className="tiny">Subgraph</div>
              <div className="code-block">{subgraphEndpoint}</div>
            </div>
          </div>
        </aside>
      </section>

      <section className="stat-grid">
        {protocolMetrics.map((metric) => (
          <article className="card" key={metric.label}>
            <div className="metric-label">{metric.label}</div>
            <div className="metric-value">{metric.value}</div>
            <div className="tiny">{metric.note}</div>
          </article>
        ))}
      </section>

      <section className="content-grid">
        <div>
          <article className="card">
            <div className="section-head">
              <div>
                <div className="section-kicker">Governance</div>
                <h2 className="section-title">Proposal Flow</h2>
              </div>
              <div className="tiny">Statuses mirror Governor + Timelock lifecycle</div>
            </div>

            <div className="proposal-list">
              {proposals.map((proposal) => (
                <div className="proposal-item" key={proposal.id}>
                  <div className="proposal-top">
                    <div>
                      <strong>
                        {proposal.id} • {proposal.title}
                      </strong>
                      <p className="tiny">{proposal.summary}</p>
                    </div>
                    <span className={statePillClass(proposal.state)}>{proposal.state}</span>
                  </div>
                  <div className="list-meta">{proposal.quorum}</div>
                </div>
              ))}
            </div>
          </article>

          <article className="card" style={{ marginTop: 18 }}>
            <div className="section-head">
              <div>
                <div className="section-kicker">Crafting</div>
                <h2 className="section-title">Active Recipes</h2>
              </div>
              <div className="tiny">DAO-governed via CraftingStation proposals</div>
            </div>

            <div className="recipe-list">
              {recipes.map((recipe) => (
                <div className="recipe-item" key={recipe.item}>
                  <strong>{recipe.item}</strong>
                  <div className="tiny">Output: {recipe.output}</div>
                  <div className="tiny">Ingredients: {recipe.ingredients}</div>
                </div>
              ))}
            </div>
          </article>
        </div>

        <div>
          <article className="card">
            <div className="section-head">
              <div>
                <div className="section-kicker">AMM</div>
                <h2 className="section-title">Resource Pools</h2>
              </div>
              <div className="tiny">Constant-product LP pairs</div>
            </div>

            <div className="pool-list">
              {pools.map((pool) => (
                <div className="pool-item" key={pool.name}>
                  <div className="pool-top">
                    <strong>{pool.name}</strong>
                    <span className="pill">{pool.fee}</span>
                  </div>
                  <div className="tiny">Reserves: {pool.reserves}</div>
                  <div className="tiny">Recent volume: {pool.volume}</div>
                </div>
              ))}
            </div>
          </article>

          <article className="card" style={{ marginTop: 18 }}>
            <div className="section-head">
              <div>
                <div className="section-kicker">Rental Vault</div>
                <h2 className="section-title">Hero Listings</h2>
              </div>
              <div className="tiny">Collateral checked through Chainlink pricing</div>
            </div>

            <div className="rental-list">
              {rentals.map((rental) => (
                <div className="rental-item" key={rental.hero}>
                  <div className="rental-top">
                    <strong>{rental.hero}</strong>
                    <span className={statePillClass(rental.status)}>{rental.status}</span>
                  </div>
                  <div className="tiny">Owner: {rental.owner}</div>
                  <div className="tiny">Fee: {rental.fee}</div>
                  <div className="tiny">Collateral: {rental.collateral}</div>
                </div>
              ))}
            </div>
          </article>

          <article className="card" style={{ marginTop: 18 }}>
            <div className="section-head">
              <div>
                <div className="section-kicker">Subgraph</div>
                <h2 className="section-title">Query Pack</h2>
              </div>
              <div className="tiny">Ready for indexed reads in the dashboard</div>
            </div>

            <div className="activity-list">
              <div className="activity-item">
                <strong>Recent governance query</strong>
                <pre className="code-block">{subgraphQueries.proposals}</pre>
              </div>
              <div className="activity-item">
                <strong>Recent swaps query</strong>
                <pre className="code-block">{subgraphQueries.swaps}</pre>
              </div>
            </div>
          </article>
        </div>
      </section>
    </main>
  );
}
