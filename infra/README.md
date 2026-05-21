# infra/

Local-only infrastructure-as-code. Everything in this directory runs on a developer laptop — no cloud accounts required.

- `docker-compose.yml` — the **data plane**: MinIO (S3-compatible object store), Redpanda (Kafka API), ClickHouse (OLAP). Brought up via `make up-compose`.
- `k8s/` — the **compute plane**:
  - `kind-cluster.yaml` — local Kubernetes cluster definition.
  - `spark-operator/` — Helm values for the Kubeflow Spark Operator.
  - `strimzi/` — Strimzi Kafka Operator + Kafka CR + KafkaTopic CRs (a second Kafka, in-cluster, alongside Compose Redpanda — see [ADR-0006](../docs/adr/0006-dual-kafka-rationale.md)).
  - `spark-apps/` — `SparkApplication` CRDs for the medallion pipelines.
  - `examples/` — canonical SparkApplication samples (`pi.yaml`) used by the smoke test.

See the top-level `Makefile` for orchestration entry points: `make up`, `make down`, `make status`, `make demo`.
