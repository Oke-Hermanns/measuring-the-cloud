#!/usr/bin/env bash

# shellcheck disable=SC1091
source storage/scripts/benchmark_defaults.sh

BENCHMARK_NAME=fio-randread-128k-iouring
BENCHMARK_TOOL=fio
SKIP=0

FIO_IOENGINE=io_uring
FIO_RW=randread
FIO_BS=128k
FIO_IODEPTH=16
FIO_NUMJOBS=1
FIO_RUNTIME_SEC=60
FIO_DIRECT=1
FIO_GROUP_REPORTING=1
FIO_TIME_BASED=1
FIO_SIZE=1G
REPETITIONS=3
COOLDOWN_SEC=5
