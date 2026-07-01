# STACKIT Filesystem Scenarios

This folder keeps a small explicit compatibility subset for filesystem-backed
storage benchmarks while the broader STACKIT scenario matrix continues to
cover the `raw` path.

The representative scenarios use the largest local-storage shape and the
highest attached block profile already modeled in the repo, with `xfs` as the
aligned filesystem-backed choice for PostgreSQL-oriented runs. The
filesystem-backed coverage is consolidated into one combined scenario that
benchmarks both the instance-local target and the attached block target on the
same VM:

- combined local `raw` plus block `raw`: `g2a.120d` with `storage_premium_perf29`
- combined local `xfs` plus block `xfs`: `g2a.120d` with `storage_premium_perf29`

This folder is intentionally limited to the combined representative scenarios:
one `raw/raw` variant and one `xfs/xfs` variant.
