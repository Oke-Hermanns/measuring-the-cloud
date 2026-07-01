# AWS Block Storage Scenarios

These scenarios use `c6id.2xlarge` to approximate the existing STACKIT
`g2a.8d` block-storage matrix and vary gp3 IOPS/throughput profiles. They now
default to direct-device benchmarking with `BLOCK_FILESYSTEM=raw`.

Like the comparable STACKIT block-storage scenarios, this folder uses the full
benchmark suite from `storage/benchmarks/full`.

The profile names are benchmark pairings, not provider-equivalent guarantees:

```text
perf6   gp3  3000 IOPS /  125 MiB/s
perf12  gp3  6000 IOPS /  250 MiB/s
perf21  gp3 10000 IOPS /  500 MiB/s
perf29  gp3 16000 IOPS / 1000 MiB/s
```

Use `../filesystem/` when you want explicit filesystem-backed comparison runs.

`aws_c6id.large_ebs-gp3_standard` is kept as a lower-cost AWS-only smoke
scenario and is not part of the direct STACKIT pairing matrix.
