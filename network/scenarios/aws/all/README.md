# AWS Network Matrix

This folder contains the broader AWS network matrix. It mirrors the STACKIT
matrix structure with approximate instance pairings:

```text
STACKIT g2a.2d    AWS c6id.large
STACKIT g2a.8d    AWS c6id.2xlarge
STACKIT g2a.120d  AWS c6id.32xlarge
```

Run the full matrix through the dedicated AWS runner with:

```bash
./scripts/provision_runner.sh \
  --runner-provider aws \
  --scenario-dir network/scenarios/aws/all
```
