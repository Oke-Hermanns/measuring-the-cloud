# AWS Full Storage Matrix

This folder contains the broader AWS block-storage matrix. It combines
approximate compute pairings with gp3 profiles:

```text
STACKIT g2a.8d    AWS c6id.2xlarge
STACKIT g2a.30d   AWS c6id.8xlarge
STACKIT g2a.120d  AWS c6id.32xlarge
```

The gp3 profile names mirror the STACKIT performance-class labels for
benchmark pairing only.

Like the comparable STACKIT matrix, these scenarios use the full benchmark
suite from `storage/benchmarks/full`.

This folder also includes the representative filesystem-backed scenarios from
`../filesystem/`:

- local-only on `xfs`
- block-only on `xfs` for the top perf29 profile
- combined local `xfs` plus block `xfs` on the same VM

The raw-only filesystem scenarios are not duplicated here because the main
matrix already covers raw runs.
