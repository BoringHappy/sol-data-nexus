# ADR-0002: Data source — public RPC with sampled-backfill scope

## Status

Accepted.

## Context

The project needs enough Solana mainnet data to compute three metric families (Nakamoto coefficient, skip rate per leader, validator REV) over a recent window. Three credible sources exist:

1. **Public Solana mainnet RPC** — free, but aggressively rate-limited (typically a few requests per second per anonymous client) and not designed for bulk historical pulls.
2. **Yellowstone gRPC / Geyser** — real-time stream with low latency; requires a paid RPC plan (Helius, Triton, etc.), roughly $50–200 / month.
3. **BigQuery public dataset** (`bigquery-public-data.crypto_solana_mainnet_us`) — bulk historical access via SQL; free up to BigQuery's monthly quota.

Constraints:

- The demo must be fully reproducible by a reviewer with no API keys.
- Total effort budget is three to four weeks; data engineering, not RPC plumbing, must be the focus.
- Full-block backfill across multiple epochs would exceed any free-tier RPC rate limit.

## Decision

We use **public Solana mainnet RPC** as the primary source, with a **sampled-backfill** scope.

**Polled-without-sampling endpoints** (small response, fits within rate limits):

- `getEpochInfo` — every 30s
- `getVoteAccounts` — every 60s
- `getBlockProduction` — once per epoch boundary
- `getLeaderSchedule` — once per epoch boundary

**Sampled endpoint** (large response, scope-limited):

- `getBlock` — fetched for every Nth slot only, configurable via env var (`SAMPLE_EVERY_N_SLOTS`, default `1000`).

**Backfill scope:** the last **3 epochs** (~6 days, ~1.3M slots). Enough for two consecutive epoch transitions, which the Nakamoto + skip-rate metrics use as a temporal axis.

The ingestor abstracts the RPC client behind a `PublicRPC` adapter so a `Helius` or `Triton` adapter can be swapped in via env var (`SOL_RPC_URL`) without code changes. Premium providers are an optional acceleration, never a requirement.

## Consequences

**Positive.**
- Zero credentials required to run the demo. A reviewer clones, runs `make up`, runs `make backfill --from-epoch X --to-epoch Y`, and sees results.
- Reproducibility is preserved: if rate limits change, the sampling factor and backfill scope are tunable.

**Negative.**
- The demo cannot make rigorous claims about latency or throughput, because polled RPC is the slowest realistic source. The architecture *supports* low-latency ingestion (Kafka is in the path), but the live numbers will not impress on that axis.
- `getBlock` sampling means transaction-level analysis (vote-tx parsing, priority-fee accounting for validator REV) is approximate. Each affected metric spec documents the sampling caveat.
- A 3-epoch backfill is a small dataset relative to a true on-chain analytics product. Acceptable scope for a demo; flagged as a known limitation.

**Reversibility.**
- Switching to Yellowstone gRPC is straightforward: add a new ingestor adapter and keep the same Kafka topic contracts. The downstream lakehouse and metric jobs are unchanged.
