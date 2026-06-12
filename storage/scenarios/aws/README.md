# AWS Storage Scenarios

These scenarios reuse `storage/scenarios/aws-baseline.tfvars` for account,
region, SSH, and networking settings.

- `aws_c6i.large_ebs-gp3_standard.sh` benchmarks an attached gp3 EBS volume.
- `aws_i4i.large_local_standard.sh` benchmarks AWS instance-store NVMe storage.

Copy `storage/scenarios/aws-baseline.tfvars.example` to
`storage/scenarios/aws-baseline.tfvars` before running real infrastructure.
