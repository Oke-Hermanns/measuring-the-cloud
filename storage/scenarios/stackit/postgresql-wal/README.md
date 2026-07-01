# Storage PostgreSQL-WAL Scenarios

This folder contains the most relevant storage scenario for PostgreSQL style
WAL workloads. It now inherits the repo-wide raw-default target config unless
explicitly overridden; when filesystem-backed representative runs are needed,
the repo aligns them on `xfs`.

Use this folder when you want the full storage benchmark matrix:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --workload storage \
  --scenario-dir storage/scenarios/stackit/postgresql-wal
```

The files may overlap with focused subset folders.
The main difference is the benchmark configuration.
