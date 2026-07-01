#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../common.inc"

SCENARIO_NAME=aws_c6id.32xlarge_local_raw
BENCHMARK_MACHINE_TYPE=c6id.32xlarge
BLOCK_VOLUME_SIZE_GIB=0
LOCAL_FILESYSTEM=raw
