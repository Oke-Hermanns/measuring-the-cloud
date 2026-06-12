# AWS Block Storage Scenarios

These scenarios use `c6id.2xlarge` to approximate the existing STACKIT
`g2a.8d` block-storage matrix and vary gp3 IOPS/throughput profiles.

The profile names are benchmark pairings, not provider-equivalent guarantees:

```text
perf6   gp3  3000 IOPS /  125 MiB/s
perf12  gp3  6000 IOPS /  250 MiB/s
perf21  gp3 10000 IOPS /  500 MiB/s
perf29  gp3 16000 IOPS / 1000 MiB/s
```
