#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../common.inc"

SCENARIO_NAME=aws_c6id.8xlarge_local_standard
BENCHMARK_MACHINE_TYPE=c6id.8xlarge
BLOCK_VOLUME_SIZE_GIB=0
