# services/

Long-running runtime services that ingest Solana data and serve it to downstream consumers. Each subdirectory is an independently deployable image.

Planned:

- `ingestor/` — Python async service that polls the public Solana RPC (`getBlock`, `getBlockProduction`, `getVoteAccounts`, `getLeaderSchedule`) and emits typed records to Kafka. See parent spec [#3](https://github.com/BoringHappy/sol-data-nexus/issues/3).
- `mcp-server/` — Python MCP server that exposes gold-layer metrics (Nakamoto coefficient, skip rate, validator REV) as tools an AI agent can call. See parent spec [#7](https://github.com/BoringHappy/sol-data-nexus/issues/7).
- `sol-rpc-tap/` (stretch) — Rust CLI alternative to the Python ingestor. See parent spec [#10](https://github.com/BoringHappy/sol-data-nexus/issues/10).

See [`docs/architecture.md`](../docs/architecture.md) for how these services fit into the overall data flow.
