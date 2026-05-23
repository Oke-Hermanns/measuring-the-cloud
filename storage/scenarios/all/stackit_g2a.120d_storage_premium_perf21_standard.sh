#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.inc"

SCENARIO_NAME=stackit_g2a.120d_storage_premium_perf21_standard
BENCHMARK_MACHINE_TYPE=g2a.120d
BLOCK_VOLUME_PERFORMANCE_CLASS=storage_premium_perf21
