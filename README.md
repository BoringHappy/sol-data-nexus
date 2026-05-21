# sol-data-nexus

> Illuminating Solana's on-chain data.

A local, fully reproducible demo of a Solana network-health data platform. Public RPC is indexed into a medallion lakehouse on MinIO + Iceberg, processed with Spark on Kubernetes, served from ClickHouse, and exposed to AI agents through an MCP server. The pipelines compute the three metric families that matter for evaluating a proof-of-stake network: **decentralization** (Nakamoto coefficient), **transaction inclusion performance** (per-leader skip rate), and (stretch) **validator economics**. Everything runs on a developer laptop with Docker + `kind` — no cloud account required.

## Architecture

```
  Solana mainnet (public RPC)
            │
            ▼
  ┌────────────────────┐
  │ services/ingestor  │  Python async — getBlock / getVoteAccounts /
  │                    │  getBlockProduction / getLeaderSchedule
  └──────────┬─────────┘
             ▼
  ┌────────────────────┐
  │ Kafka              │  Compose Redpanda (dev) + Strimzi on k8s (demo)
  └──────────┬─────────┘
             ▼
  ┌────────────────────┐    ┌──────────────────────────────┐
  │ MinIO + Iceberg    │◀──▶│ pipelines/ (Spark on k8s)    │
  │ bronze→silver→gold │    │ bronze→silver, silver→gold   │
  └──────────┬─────────┘    └──────────────────────────────┘
             ▼
  ┌────────────────────┐
  │ ClickHouse         │  OLAP serving for the gold layer
  └──────────┬─────────┘
             ▼
  ┌────────────────────┐
  │ services/mcp-server│  get_nakamoto, get_skip_rate, ...
  └──────────┬─────────┘
             ▼
       Claude / any MCP client
```

See [`docs/architecture.md`](docs/architecture.md) for per-component descriptions, data-flow narrative, and alternatives considered. See [`docs/adr/`](docs/adr/) for the decisions that shaped this design.

## Quickstart

```bash
# Prerequisites: Docker, kind, kubectl, helm, make
make help            # see all available targets

# Available after task #15 lands:
make up              # bring up the whole stack (Compose data plane + k8s compute plane)
make test-smoke      # verify everything is healthy
make demo            # run the end-to-end demo
make down            # tear down
```

A full reproduction guide is in `docs/runbook.md` (added by [task #15](https://github.com/BoringHappy/sol-data-nexus/issues/15)).

## What's in this repo

| Path | Purpose |
|---|---|
| [`services/`](services/) | Long-running services (RPC ingestor, MCP server). |
| [`pipelines/`](pipelines/) | PySpark medallion pipelines (bronze → silver → gold). |
| [`infra/`](infra/) | Local-only infrastructure: Docker Compose + kind / Spark Operator / Strimzi manifests. |
| [`specs/`](specs/) | SIMD-style metric specifications. |
| [`docs/`](docs/) | Architecture doc, ADRs, runbook, demo assets. |
| [`tests/`](tests/) | Smoke tests, PySpark unit tests, metric golden-file tests. |

## Status

Work is decomposed into specs (issues labelled [`spec`](https://github.com/BoringHappy/sol-data-nexus/issues?q=label%3Aspec)) and each spec into tasks (issues labelled [`task`](https://github.com/BoringHappy/sol-data-nexus/issues?q=label%3Atask)). The current focus is [Spec #2: Foundation](https://github.com/BoringHappy/sol-data-nexus/issues/2).

## License

[MIT](LICENSE).
