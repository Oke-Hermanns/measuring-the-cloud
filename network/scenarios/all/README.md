# Network All Scenarios

This folder contains the broad network scenario set used for full report runs.
It combines placement classes, availability zones, instance types, and OS
tuning profiles into explicit scenario files.

Use this folder when you want the full network benchmark matrix:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --scenario-dir network/scenarios/all
```

The files intentionally duplicate scenarios that also appear in focused subset
folders. This keeps the "run everything" entry point stable while still
allowing smaller targeted runs.
