# Architecture

This document is the canonical map of `sol-data-nexus`. The README has a one-paragraph pitch; this is where the actual reasoning lives.

The system is a **local-only Solana network-health data platform**. Its single product is a set of gold-layer metrics — decentralization, transaction inclusion performance, and (stretch) validator economics — exposed via SQL and via an MCP server. Everything else exists to feed those metrics with correct, reproducible data.

## Diagram

```
  Solana mainnet (public RPC)
            │
            ▼
  ┌────────────────────────────────┐
  │ services/ingestor              │  Python async; rate-limited polls of
  │                                │  getBlock, getBlockProduction,
  │                                │  getVoteAccounts, getLeaderSchedule
  └──────────────┬─────────────────┘
                 ▼
  ┌────────────────────────────────┐
  │ Kafka                          │  Compose Redpanda (dev convenience)
  │                                │  + Strimzi on k8s (cloud-native demo)
  │  topics: sol.raw.{epoch_info,  │  KRaft, single broker, RF=1 locally
  │  vote_accounts, block_         │
  │  production, leader_schedule,  │
  │  blocks}                       │
  └──────────────┬─────────────────┘
                 ▼
  ┌────────────────────────────────┐    ┌─────────────────────────────────┐
  │ MinIO (S3-compatible)          │◀──▶│ pipelines/ (Spark on k8s)       │
  │ + Apache Iceberg               │    │                                 │
  │                                │    │  bronze_to_silver/  : decode    │
  │  bronze/  : raw JSON           │    │    raw JSON, build typed tables │
  │  silver/  : decoded entities   │    │                                 │
  │  gold/    : metric outputs     │    │  silver_to_gold/  : compute     │
  │                                │    │    Nakamoto, skip rate, REV     │
  └──────────────┬─────────────────┘    └─────────────────────────────────┘
                 ▼
  ┌────────────────────────────────┐
  │ ClickHouse                     │  OLAP serving over gold layer.
  │                                │  Loaded via Iceberg external table
  │                                │  OR Spark JDBC sink (see ADR-0006).
  └──────────────┬─────────────────┘
                 ▼
  ┌────────────────────────────────┐
  │ services/mcp-server (Python)   │  Tools:
  │                                │   • get_nakamoto_coefficient(epoch)
  │                                │   • get_skip_rate(epoch, validator?)
  │                                │   • list_top_validators_by_stake(...)
  │                                │   • describe_metric(name)
  └──────────────┬─────────────────┘
                 ▼
       Claude Desktop / Claude Code / any MCP-compatible agent
```

## Components

Each subsection names the component, its role, the line(s) of the Solana Foundation Senior Data Engineer JD it maps to, and where in the repo it lives.

### Ingestor (`services/ingestor/`)

Python `asyncio` service that polls the Solana public RPC and emits raw records to Kafka. Five extractors (`epoch_info`, `vote_accounts`, `block_production`, `leader_schedule`, sampled `blocks`) share a token-bucket rate limiter and an exponential-backoff-with-jitter retry policy. Two modes: `backfill` for historical replays, `tail` for live demos.

- **JD mapping:** *"Collaborate with blockchain engineers to index blockchain data and create robust data pipelines"*, *"high performance and low latency"*.
- Stretch sibling: `services/sol-rpc-tap/` is a Rust reimplementation of the same five extractors. It hits the JD's Rust bonus line.

### Kafka — two flavours

Two Kafka deployments coexist on purpose; ADR-0006 explains why.

1. **Compose Redpanda** (`infra/docker-compose.yml`) — single-node, KRaft mode, schema registry on the side. Used for fast dev iteration; the ingestor talks to it by default.
2. **Strimzi Kafka on k8s** (`infra/k8s/strimzi/`) — managed by the Strimzi Operator on the kind cluster. Single broker, persistent volume, NodePort listener. Used to demonstrate a cloud-native streaming layer and exercise k8s networking.

- **JD mapping:** *"Kafka, RabbitMQ, Pub/Sub"*, *"distributed data systems and cloud platforms"*.

### Lakehouse: MinIO + Iceberg

MinIO provides an S3-compatible blob store (`bronze/`, `silver/`, `gold/` buckets). Apache Iceberg sits on top, giving us schema evolution, snapshotting, and time-travel — and the table format the Solana Foundation has explicitly cited in the JD. The catalog is wired in via the Hadoop catalog adapter against MinIO; ADR-0005 documents the choice.

- **JD mapping:** *"Strong understanding in one of the following big data frameworks: ... Iceberg ..."*.

### Spark on Kubernetes (`pipelines/`)

PySpark jobs run as `SparkApplication` CRDs on a local `kind` cluster, managed by the Kubeflow Spark Operator. Two pipeline families:

- `bronze_to_silver/` — decode the raw JSON into typed entity tables (`validator_stake_snapshots`, `leader_schedule`, `block_production`, `vote_txs`).
- `silver_to_gold/` — compute the three metric families (`nakamoto_coefficient`, `skip_rate`, stretch `validator_rev`).

Each job ships as a `SparkApplication` YAML under `infra/k8s/spark-apps/`, mirroring how it would be deployed on a managed cluster (EMR, GKE, Databricks).

- **JD mapping:** *"Strong understanding in one of the following big data frameworks: Spark"*, *"distributed data systems and cloud platforms"*.

### ClickHouse (serving)

ClickHouse reads the Iceberg gold layer either as an external table or via a periodic Spark JDBC sink (ADR-0006 picks one); the result is sub-second OLAP queries for the demo. The MCP server points at ClickHouse, never at the raw lakehouse.

- **JD mapping:** *"Clickhouse, Databricks, Snowflake, BigQuery"*.

### MCP server (`services/mcp-server/`)

Python service using the official `mcp` SDK. Exposes a small set of tools that wrap ClickHouse queries: `get_nakamoto_coefficient`, `get_skip_rate`, `list_top_validators_by_stake`, `describe_metric`. The screen-recorded demo shows Claude Desktop calling these tools and answering Solana network-health questions live.

- **JD mapping (bonus):** *"Have served AI use cases through deploying live agents or MCP to production environments"*.

## Data flow (medallion)

The lakehouse follows the standard bronze / silver / gold pattern.

**Bronze — raw, append-only.** Kafka topics are persisted to Iceberg with one-to-one structural fidelity (the bronze schema is essentially the RPC response). No interpretation, no joins, no de-duplication beyond Kafka's own idempotent delivery. Bronze is the source of truth that lets us re-derive everything downstream without re-fetching from RPC.

**Silver — decoded, typed, joined.** PySpark jobs read bronze and produce entity-shaped tables: one row per validator per epoch in `silver.validator_stake_snapshots`; one row per leader-slot in `silver.leader_schedule`; one row per leader per epoch in `silver.block_production`; one row per vote tx in `silver.vote_txs`. Silver is schema-stable and is the contract the metric jobs depend on.

**Gold — metric outputs.** Per-spec PySpark jobs read silver and write `gold.nakamoto_coefficient_by_epoch`, `gold.skip_rate_by_leader_epoch`, `gold.skip_rate_network_epoch`, and (stretch) `gold.validator_rev_by_epoch`. Each metric has a SIMD-style specification doc under [`specs/`](../specs/) that defines exactly what the table means, how edge cases are handled, and how it cross-validates against a public source.

**Serving.** ClickHouse reads gold; the MCP server queries ClickHouse; agents call the MCP server. The dashboard layer (a Grafana stretch goal under Spec #8) would also read ClickHouse.

## Alternatives considered

For each major choice, the brief alternative case is on record here so a reviewer can see the trade-off explicitly. Full ADRs live under [`docs/adr/`](adr/).

- **Iceberg vs Delta Lake vs Hudi.** Iceberg is named in the JD; Delta-rs is also named. Iceberg has the best multi-engine reader story (Spark, ClickHouse, Trino, Flink) and is the natural fit for a Spark-on-k8s + ClickHouse stack. Delta-rs would have been the Rust-native pick if the ingestor were Rust-only.
- **Spark vs Polars vs Delta-rs.** Spark wins because (a) it's named in the JD, (b) it demonstrates "distributed data systems on cloud platforms" in a way local Polars cannot, and (c) `SparkApplication` CRDs on k8s mirror how the job would run on a managed cluster.
- **kind vs minikube vs k3d.** kind has the best documentation around `extraHosts` and inter-cluster networking, which matters because Spark pods need to reach Compose-hosted MinIO and Redpanda.
- **Public RPC vs Yellowstone gRPC vs BigQuery public dataset.** Public RPC was chosen for cost (free) and reproducibility (no API key required to run the demo). Backfill is scoped to a small epoch window with sampled blocks because full block backfill would exceed public RPC rate limits.
- **Compose-only Kafka vs Strimzi-only vs both.** Both — ADR-0006 details the dual-Kafka rationale. The short version: Compose is for dev velocity, Strimzi is to demonstrate cloud-native streaming.
- **Web UI vs MCP-only.** MCP-only for the core demo; a Grafana dashboard is a stretch under Spec #8. AI-agent serving is more on-brand for the JD's "live agents or MCP" bonus line.

## Non-goals

What `sol-data-nexus` is *not*:

- Not a production indexer. It is a portfolio demonstration with a fixed metric scope.
- Not a real-time low-latency system. The streaming infrastructure exists to show the *shape* of a low-latency pipeline; the actual data is polled at epoch boundaries.
- Not a comprehensive Solana analytics platform. Three metric families. That is the scope.
- Not deployable as-is to cloud. The infra/ tree assumes local Docker + kind. Migrating to GKE / EKS / AKS would require an ADR and corresponding Terraform, which is out of scope.
