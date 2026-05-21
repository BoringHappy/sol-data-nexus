# ADR-0003: Metric scope — Nakamoto + skip rate (core); validator REV (stretch)

## Status

Accepted.

## Context

The JD names three metric families as targets: **decentralization scores, transaction inclusion performance,** and **economics**. The project has time to deliver at most three metric implementations to depth — each with a SIMD-style specification, a PySpark job, golden-file tests, and cross-validation against a public source.

The candidate metrics within each family are many; we have to pick one per family that:

1. Is well-defined enough to compute correctly from public data.
2. Can be cross-validated against a public reference (validators.app, Solana Beach).
3. Is recognizable to a Solana Foundation reviewer.

## Decision

**Core metrics (must ship)** — one each from the first two JD families:

- **Decentralization → Nakamoto coefficient.** The minimum number of validators whose combined stake exceeds 33.3% of total active stake. Computable from `getVoteAccounts` alone; cheapest end-to-end demo path; canonical for any PoS chain.
- **Transaction inclusion performance → Skip rate per leader per epoch.** Skipped-slots / assigned-slots from `getBlockProduction` + `getLeaderSchedule`. The simplest, most-cited inclusion metric on Solana.

**Stretch metric (only after core ships)** — from the third JD family:

- **Economics → Validator REV per epoch.** Inflation reward + priority fees + (proxy) MEV, normalized per SOL staked. Tagged stretch because it requires `getBlock` sampling (vote-tx parsing, priority-fee aggregation) and has more edge cases (sampling caveat, vote-cost approximation, MEV not directly observable from RPC).

**Explicitly excluded** for this iteration (could become future specs):

- Gini coefficient, validator client diversity, geographic distribution (decentralization extensions).
- Priority-fee-weighted landing rate, per-transaction tracing (inclusion extensions).
- Per-staker yield, MEV-direct measurement (economics extensions).

Each of the above is flagged as a future spec in the relevant SIMD document under [`specs/`](../../specs/).

## Consequences

**Positive.**
- Each metric maps to a different JD-named family; the demo can claim coverage of decentralization + inclusion (and stretch economics) without overcommitting.
- Both core metrics use small, well-understood RPC endpoints; cross-validation against validators.app is feasible.
- Each metric gets its own SIMD-style specification — itself a deliverable that demonstrates the documentation expectation in the JD.

**Negative.**
- Three metrics is a small surface area for a "data platform" demo. The serving layer + lakehouse infrastructure compensates for the narrow analytics surface, but it does mean the demo's selling point is *depth and rigor*, not breadth.
- The economics metric is stretch precisely because it's the hardest to compute correctly from public RPC. If we fall short on REV, the demo still covers decentralization + inclusion convincingly.
