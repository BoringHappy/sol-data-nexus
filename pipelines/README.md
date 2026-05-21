# pipelines/

Batch PySpark jobs that run on the local Spark Operator (`infra/k8s/spark-operator/`). Organized as a medallion lakehouse.

Planned:

- `bronze_to_silver/` — decode raw Kafka / Iceberg-bronze data into typed entity tables (`validator_stake_snapshots`, `leader_schedule`, `block_production`, `vote_txs`). See parent spec [#4](https://github.com/BoringHappy/sol-data-nexus/issues/4).
- `silver_to_gold/` — compute the demo's network-health metrics:
  - `nakamoto_coefficient.py` — decentralization. See spec [#5](https://github.com/BoringHappy/sol-data-nexus/issues/5).
  - `skip_rate.py` — transaction inclusion performance. See spec [#6](https://github.com/BoringHappy/sol-data-nexus/issues/6).
  - `validator_rev.py` (stretch) — economics. See spec [#9](https://github.com/BoringHappy/sol-data-nexus/issues/9).

Each job is packaged as a `SparkApplication` CRD under `infra/k8s/spark-apps/`.
