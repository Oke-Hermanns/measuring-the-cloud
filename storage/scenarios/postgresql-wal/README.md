# Storage PostgreSQL-WAL Scenarios

This folder contains the most relevant storage scenario for PostgreSQL style WAL workloads.

Use this folder when you want the full storage benchmark matrix:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --workload storage \
  --scenario-dir storage/scenarios/postgresql-wal
```

The files may overlap with focused subset folders.
The main difference the execute benchmark configuration
