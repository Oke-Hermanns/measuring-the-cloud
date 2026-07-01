# AWS Local Storage Scenarios

These scenarios use c6id instance-store NVMe devices and disable the additional
EBS benchmark block volume with `BLOCK_VOLUME_SIZE_GIB=0`. They now default to
direct-device benchmarking with `LOCAL_FILESYSTEM=raw`.

Like the comparable STACKIT local-storage scenarios, this folder uses the full
benchmark suite from `storage/benchmarks/full`.

`c6id.8xlarge` and `c6id.32xlarge` are included as approximate local-storage
pairings for larger STACKIT `g2a` local-storage scenarios. They can be
expensive; use `--dry-run` first and check quota/cost before provisioning.

`aws_c6id.large_local_standard` is kept as a lower-cost AWS-only smoke scenario
and is not part of the direct STACKIT pairing matrix.

Use `../filesystem/` when you want explicit filesystem-backed comparison runs.
