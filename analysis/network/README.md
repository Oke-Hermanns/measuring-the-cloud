# Network Benchmark Analysis

This folder contains the network parsing layer for artifacts under `artifacts/network`.

## Generate CSVs

Generate CSVs for all available network runs:

```bash
Rscript analysis/network/build_csv.R all
```

Generate CSVs for a single run:

```bash
Rscript analysis/network/build_csv.R run-20260523-171439
```

Generate CSVs for selected runs:

```bash
Rscript analysis/network/build_csv.R run-20260523-171439,run-20260523-204710
```

The output is written to `analysis/network/<result-id>/`.

## Output Files

- `network_scenarios.csv`: one row per scenario and run.
- `network_iperf3.csv`: one row per iperf3 repetition.
- `network_iperf3_intervals.csv`: one row per iperf3 interval from the client JSON output.
- `network_sockperf.csv`: one row per sockperf repetition.

## Validate CSVs

```bash
Rscript analysis/network/validate_csv.R all
```

For `all`, validation compares CSV row counts against the raw artifact files and
runs DuckDB sanity checks for protocol-specific fields and key aggregations.

## Render The Report

```bash
Rscript analysis/network/render_network_benchmark_analysis.R all
```

The report is written to:

```text
analysis/network/<result-id>/network_benchmark_analysis_<result-id>.html
```

The renderer regenerates CSVs before rendering. If no result id is passed, it
renders `all`.
