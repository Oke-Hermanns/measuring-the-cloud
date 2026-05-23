#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.inc"

SCENARIO_NAME=stackit_g2a.120d_eu01-3_different-host_standard
OS_TUNING=standard
INSTANCE_AFFINITY=different-host
CLIENT_MACHINE_TYPE=g2a.120d
SERVER_MACHINE_TYPE=g2a.120d
CLIENT_AVAILABILITY_ZONE=eu01-1
SERVER_AVAILABILITY_ZONE=eu01-3
PLACEMENT_MODE=multi-az
