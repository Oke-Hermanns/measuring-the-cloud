# Storage Analysis

This directory contains the CSV parsing and validation step for the storage benchmarks.

## Build CSVs

```bash
nix develop .#analysis --command Rscript analysis/storage/build_csv.R all
```

The parser writes:

- `analysis/storage/all/storage_scenarios.csv`
- `analysis/storage/all/storage_benchmarks.csv`
- `analysis/storage/all/storage_fio.csv`
- `analysis/storage/all/storage_failures.csv`

You can also pass a specific run id:

```bash
nix develop .#analysis --command Rscript analysis/storage/build_csv.R run-20260524-002524
```

## Validate

```bash
nix develop .#analysis --command Rscript analysis/storage/validate_csv.R all
```

Validation checks:

- CSV row counts against the raw storage artifacts
- `local`/`block` target normalization
- benchmark family metadata
- invalid fio runs captured in `storage_failures.csv`

## Render Report

```bash
nix develop .#analysis --command Rscript analysis/storage/render_storage_benchmark_analysis.R all
```

This produces:

- `analysis/storage/all/storage_benchmark_analysis_all.html`
