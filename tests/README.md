# tests/

Test scripts and fixtures.

- `smoke/` — shell scripts that verify the live local stack end-to-end (bucket creation, topic creation, `SELECT 1`, `SparkApplication` apply). Run via `make test-smoke`. Filled in by task [#15](https://github.com/BoringHappy/sol-data-nexus/issues/15).
- `pipelines/` (later) — PySpark unit tests for the bronze-to-silver and silver-to-gold jobs.
- `metrics/` (later) — golden-file tests for each metric: fixed input → known output. One subdirectory per metric (`nakamoto/`, `skip_rate/`, ...).

Smoke tests verify infrastructure; unit tests verify code; golden-file tests verify metric math. All three must pass before a metric is published.
