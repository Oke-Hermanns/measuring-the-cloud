# STACKIT Filesystem Scenarios

This folder keeps a small explicit compatibility subset for filesystem-backed
storage benchmarks while the broader STACKIT scenario matrix defaults to
`raw`.

The representative scenarios use the largest local-storage shape and the
highest attached block profile already modeled in the repo, with `xfs` as the
aligned filesystem-backed choice for PostgreSQL-oriented runs:

- local: `g2a.120d`
- block: `g2a.120d` with `storage_premium_perf29`

Each target has both a `raw` and a filesystem-backed variant so you can test
transition behavior and compare mounted-filesystem overhead without running the
full historical matrix.

The folder also includes one combined filesystem-backed scenario that exercises
the `all`-style case where both the local instance-local target and the
attached block target are benchmarked on the same VM.
