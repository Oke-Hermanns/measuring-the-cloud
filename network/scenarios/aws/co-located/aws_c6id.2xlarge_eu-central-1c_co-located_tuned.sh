#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../common.inc"

SCENARIO_NAME=aws_c6id.2xlarge_eu-central-1c_co-located_tuned
OS_TUNING=network-throughput
INSTANCE_AFFINITY=co-located
CLIENT_MACHINE_TYPE=c6id.2xlarge
SERVER_MACHINE_TYPE=c6id.2xlarge
CLIENT_AVAILABILITY_ZONE=eu-central-1c
SERVER_AVAILABILITY_ZONE=eu-central-1c
PLACEMENT_MODE=single-az
