# AWS Storage Scenarios

These scenarios reuse `storage/scenarios/aws/baseline.tfvars` for account,
region, SSH, and networking settings.

- `block-storage/` benchmarks attached gp3 EBS profiles.
- `local-storage/` benchmarks AWS instance-store NVMe storage.
- `postgresql-wal/` benchmarks WAL-shaped storage profiles.
- `all/` contains the broader AWS block-storage matrix.

Copy `storage/scenarios/aws/baseline.tfvars.example` to
`storage/scenarios/aws/baseline.tfvars` before running real infrastructure.
