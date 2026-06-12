# AWS Network Scenarios

Focused AWS scenarios for validating EC2 network placement behavior.

Copy and edit the shared AWS baseline tfvars before running:

```bash
cp network/scenarios/aws-baseline.tfvars.example network/scenarios/aws-baseline.tfvars
```

Current placement mapping:

- `INSTANCE_AFFINITY=none`: no EC2 placement group
- `INSTANCE_AFFINITY=co-located`: EC2 cluster placement group
- `INSTANCE_AFFINITY=different-host`: EC2 spread placement group

Cluster placement is intentionally modeled as single-AZ only.
