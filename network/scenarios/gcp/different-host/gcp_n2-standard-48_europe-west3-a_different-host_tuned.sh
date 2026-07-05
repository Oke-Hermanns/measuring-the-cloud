#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../common.inc"

SCENARIO_NAME=gcp_n2-standard-48_europe-west3-a_different-host_tuned
OS_TUNING=network-throughput
INSTANCE_AFFINITY=different-host
CLIENT_MACHINE_TYPE=n2-standard-48
SERVER_MACHINE_TYPE=n2-standard-48
CLIENT_AVAILABILITY_ZONE=europe-west3-a
SERVER_AVAILABILITY_ZONE=europe-west3-a
PLACEMENT_MODE=single-az
ENABLE_TIER1_NETWORKING=true