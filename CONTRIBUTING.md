## Contributing

This repo is a working draft, not a manifesto. We welcome:

- **Empirical corrections** — real bandwidth traces, real workload measurements that support or break the Locality-of-Bandwidth (LoB) hypothesis.
- **Counter-arguments** — cases where the dual-track boundary fails (long-context prefill, tightly-coupled agentic pipelines, raw video ingest, etc.).
- **Prior art we missed** — papers, patents, products, or roadmaps.
- **Diagram improvements** — the current SVG is a first pass; better renderings welcome.
- **Prose edits** — grammar, clarity, tone. Both English and Chinese welcome.

### Style

- Keep it substantive. No hype, no vaporware.
- Cite sources when you can.
- If you're proposing a change to the architecture, explain the trade-off.

### Process

1. Open an issue first if the change is non-trivial. Discussion is welcome before code.
2. For paper edits, PRs against `paper.md`. Note in the PR what section you touched.
3. For architecture proposals, add a short design note under `docs/` and reference it from the paper.
4. Version stamps: bump the paper version in the file header if the change is substantive.

### Sign-off

By contributing you agree that your contribution is released under **CC BY 4.0** (same as the rest of the repository).
