# Storage All Scenarios

This folder contains the broad storage scenario set used for full report runs.
It combines instance types and block volume performance classes into explicit
scenario files.

Use this folder when you want the full storage benchmark matrix:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --workload storage \
  --scenario-dir storage/scenarios/stackit/all
```

The files may overlap with focused subset folders. That duplication is
intentional: this folder is the stable "run everything" entry point.
