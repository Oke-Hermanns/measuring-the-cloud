# AWS Filesystem Scenarios

This folder keeps a small explicit compatibility subset for filesystem-backed
storage benchmarks while the broader AWS scenario matrix defaults to `raw`.

The representative scenarios use the largest local-storage shape and the
highest gp3 profile already modeled in the repo, with `xfs` as the aligned
filesystem-backed choice for PostgreSQL-oriented runs:

- local: `c6id.32xlarge`
- block: `c6id.32xlarge` with gp3 perf29-equivalent settings

Each target has both a `raw` and a filesystem-backed variant so you can test
transition behavior and compare mounted-filesystem overhead without running the
full historical matrix.

The folder also includes one combined filesystem-backed scenario that exercises
the `all`-style case where both the local instance-store target and the
attached block target are benchmarked on the same VM.
