# specs/

SIMD-style metric specifications. Each metric implemented in `pipelines/silver_to_gold/` gets a versioned document here.

Each spec defines:

- **Mathematical definition** — exact formula and threshold rationale.
- **Input contract** — which silver table(s) it reads.
- **Output contract** — the shape of the gold table it writes.
- **Edge cases** — and how each is handled.
- **Cross-validation** — deviation report against a public source (validators.app, Solana Beach, etc.).
- **Versioning policy** — how a change to the metric is released.

Planned:

- `0001-nakamoto-coefficient.md` (spec [#5](https://github.com/BoringHappy/sol-data-nexus/issues/5))
- `0002-skip-rate.md` (spec [#6](https://github.com/BoringHappy/sol-data-nexus/issues/6))
- `0003-validator-rev.md` (stretch spec [#9](https://github.com/BoringHappy/sol-data-nexus/issues/9))

These documents are load-bearing artifacts of the demo — the code computes what the specs define, and the specs are what a reviewer reads to evaluate correctness.
