# Architecture Decision Records

Each ADR documents one substantive decision in the Michael Nygard format:

1. **Title** — the decision, stated affirmatively (e.g. `Use Iceberg on MinIO for the lakehouse`).
2. **Status** — `Proposed` / `Accepted` / `Deprecated` / `Superseded by ADR-NNNN`.
3. **Context** — what forced the decision; the constraints and goals in play.
4. **Decision** — what we decided. One paragraph or a few bullets.
5. **Consequences** — what becomes easier, what becomes harder, what we now have to live with.

ADRs are numbered in the order they are accepted. Renumbering is forbidden. Superseded ADRs stay in the tree, with their status updated to point at the superseder.

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-stack-lock-in.md) | Stack lock-in: Spark-on-k8s + Iceberg + Kafka + ClickHouse + MCP | Accepted |
| [0002](0002-data-source.md) | Data source: public RPC with sampled-backfill scope | Accepted |
| [0003](0003-metric-scope.md) | Metric scope: Nakamoto + skip rate as core; REV as stretch | Accepted |
| [0004](0004-local-only-deployment.md) | Local-only deployment posture (Docker + kind, no cloud) | Accepted |

ADR-0005 (Iceberg catalog choice) is reserved for task [#13](https://github.com/BoringHappy/sol-data-nexus/issues/13). ADR-0006 (dual-Kafka rationale) is reserved for task [#14](https://github.com/BoringHappy/sol-data-nexus/issues/14).
