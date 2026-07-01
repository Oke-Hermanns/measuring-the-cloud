#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../local-storage/common.inc"

SCENARIO_NAME=stackit_g2a.120d_local_raw
BENCHMARK_MACHINE_TYPE=g2a.120d
LOCAL_FILESYSTEM=raw
