#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.inc"

SCENARIO_NAME=stackit_g2a.8d_storage_premium_perf6_standard
BENCHMARK_MACHINE_TYPE=g2a.8d
BLOCK_VOLUME_PERFORMANCE_CLASS=storage_premium_perf6
