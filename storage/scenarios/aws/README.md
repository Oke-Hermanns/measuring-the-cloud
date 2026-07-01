# AWS Storage Scenarios

These scenarios reuse `storage/scenarios/aws/baseline.tfvars` for account,
region, SSH, and networking settings. The general AWS scenario matrix mirrors
the STACKIT baseline by using `storage/benchmarks/full`; only the
`postgresql-wal/` subset uses a different benchmark directory.

Two AWS-only lower-cost smoke scenarios remain outside the strict provider
pairing matrix:
- `local-storage/aws_c6id.large_local_standard.sh`
- `block-storage/aws_c6id.large_ebs-gp3_standard.sh`

- `block-storage/` benchmarks attached gp3 EBS profiles and now defaults to `raw`.
- `local-storage/` benchmarks AWS instance-store NVMe storage and now defaults to `raw`.
- `filesystem/` keeps a small explicit raw-vs-filesystem comparison subset.
- `postgresql-wal/` benchmarks WAL-shaped storage profiles.
- `all/` contains the broader AWS block-storage matrix and now defaults to `raw`.

Copy `storage/scenarios/aws/baseline.tfvars.example` to
`storage/scenarios/aws/baseline.tfvars` before running real infrastructure.
