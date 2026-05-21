# ADR-0004: Local-only deployment posture (Docker + kind, no cloud)

## Status

Accepted.

## Context

The project could be deployed to any of GCP, AWS, or Azure (all named in the JD). Cloud deployment would let a reviewer see a live URL instead of a local stack, and would demonstrate cloud-platform fluency more directly.

Counter-pressures:

- Cloud spend during a 3–4 week iteration is a real cost, with no guarantee the demo is reviewed.
- A reviewer *running* the demo locally is a stronger signal than a screenshot of a live URL — it proves reproducibility.
- The k8s components on a local `kind` cluster ARE the same primitives that would run on GKE / EKS / AKS; the demonstration of "distributed data systems on cloud platforms" does not require an actual cloud provider — only the cloud-native operators (Spark Operator, Strimzi Operator).
- Three to four weeks is too short to also do a clean Terraform / Helm-chart-for-cloud story alongside the actual data work.

## Decision

`sol-data-nexus` runs **only locally**. Specifically:

- **Data plane:** Docker Compose (MinIO, Redpanda, ClickHouse).
- **Compute plane:** `kind` cluster (Spark Operator, Strimzi Kafka).
- **No cloud provider** is required to run the demo end-to-end.
- **No Terraform / CDK / Pulumi.** Infrastructure-as-code is limited to `docker-compose.yml`, k8s manifests, and Helm values.

The README's "Quickstart" guarantees a reviewer can `make up && make demo` from a clean machine with only Docker + `kind` + `kubectl` + `helm` + `make` installed.

## Consequences

**Positive.**
- Zero cloud spend during development and review.
- Reproducibility is provable: anyone with the listed prerequisites can reach a green smoke test in under ten minutes (Spec [#2](https://github.com/BoringHappy/sol-data-nexus/issues/2) acceptance criteria).
- The k8s side still credibly demonstrates "distributed data systems and cloud platforms" because the operators (Spark, Strimzi) are the same ones a cloud deployment would use.

**Negative.**
- No live URL for a reviewer to poke without running the stack. The screen-recorded demo (Spec [#8](https://github.com/BoringHappy/sol-data-nexus/issues/8)) is what reviewers see first.
- `kind` worker nodes have constrained resources; Spark executor sizing is small (e.g., 2 executors × 2GB by default). Performance numbers are not representative of a cloud deployment.
- We forgo demonstrating fluency with a specific cloud provider (GCP, AWS, Azure). Flagged as a knowing tradeoff. Future work could add an `infra/terraform/` tree if the project goes further.

**Reversibility.**
- The system is portable on paper: MinIO → S3 / GCS / Azure Blob; Compose Redpanda → MSK / Confluent / Aiven; Spark-on-`kind` → Spark-on-GKE/EKS. A cloud rewrite would touch `infra/` only.
