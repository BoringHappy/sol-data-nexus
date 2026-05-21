# ADR-0001: Stack lock-in — Spark-on-k8s + Iceberg + Kafka + ClickHouse + MCP

## Status

Accepted.

## Context

`sol-data-nexus` exists to demonstrate end-to-end Solana data engineering for a Solana Foundation Senior Data Engineer application. The JD names specific technologies — Spark, Iceberg, Polars, Delta-rs as big-data frameworks; ClickHouse, Databricks, Snowflake, BigQuery as analytical stores; Kafka, RabbitMQ, Pub/Sub as messaging — and asks for evidence of "distributed data systems on cloud platforms" plus, as a bonus, "live agents or MCP to production environments". The project has roughly three to four weeks of part-time effort before submission, and must run on a developer laptop without cloud spend.

We need a stack that:

1. Maps each major component to a line in the JD.
2. Is locally runnable end-to-end so a reviewer can reproduce in under ten minutes.
3. Is real enough to be defensible — no toy substitutes for production-shape choices.

## Decision

We adopt the following stack, locking in one choice per layer:

| Layer | Choice | Why |
|---|---|---|
| Ingestion | Python `asyncio` against public Solana RPC | Cheapest credible ingestion; Rust alternative is a stretch (Spec [#10](https://github.com/BoringHappy/sol-data-nexus/issues/10)). |
| Messaging | **Kafka, two flavours**: Compose Redpanda for dev, Strimzi Kafka on k8s for the demo | JD names Kafka; dual deployment lets us exercise both Compose ergonomics and cloud-native operators. Detailed in ADR-0006 once filed. |
| Object store | **MinIO** (S3-compatible) | Free, local, identical S3 contract to cloud lakehouses. |
| Table format | **Apache Iceberg** | Named explicitly in the JD; best multi-engine reader story (Spark + ClickHouse + Trino). |
| Compute | **Spark on Kubernetes** via the Kubeflow Spark Operator on a local `kind` cluster | JD names Spark; `SparkApplication` CRDs mirror how the job runs on EMR / Databricks / GKE. |
| OLAP serving | **ClickHouse** | Named in the JD; sub-second OLAP over the gold layer; reads Iceberg externally. |
| AI / agent serving | **MCP server** (Python, official `mcp` SDK) | Hits the JD's "live agents or MCP to production" bonus line; serves the same metrics that ClickHouse does. |
| Visualization | **None in core scope**; Grafana over ClickHouse as a stretch | A screen recording of Claude Desktop calling MCP tools is a stronger artifact than a dashboard at this scope. |

## Consequences

**Positive.**
- Every component above maps directly to a line in the JD; the demo's claim *"this is the kind of work the role does"* is defensible.
- Spark-on-k8s + Iceberg on MinIO is a real, reproducible lakehouse pattern — not a toy substitute.
- ClickHouse + MCP gives the demo both a human-facing serving layer (SQL) and an agent-facing serving layer (MCP) with the same backing data.

**Negative.**
- We are not using Polars or Delta-rs (also named in the JD). Two engines would dilute the demo with little added signal at this scope; the alternatives are acknowledged in [`docs/architecture.md`](../architecture.md) and remain credible future extensions.
- Spark on a local `kind` cluster is memory-hungry. Local resource constraints are accepted as a tradeoff for the "distributed data systems" signal.
- Running both Compose Redpanda and Strimzi Kafka is unusual for production. Justified in ADR-0006.

**Reversibility.**
- Compute layer (Spark) is the most expensive to change after silver-layer tables exist; reversibility cost is high.
- Serving layer (ClickHouse, MCP) is the cheapest to swap; reversibility cost is low.
