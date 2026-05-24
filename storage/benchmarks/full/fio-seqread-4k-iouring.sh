#!/usr/bin/env bash

# shellcheck disable=SC1091
source storage/scripts/benchmark_defaults.sh

BENCHMARK_NAME=fio-seqread-4k-iouring
BENCHMARK_TOOL=fio
SKIP=0

FIO_IOENGINE=io_uring
FIO_RW=read
FIO_BS=4k
FIO_IODEPTH=32
FIO_NUMJOBS=1
FIO_RUNTIME_SEC=60
FIO_DIRECT=1
FIO_GROUP_REPORTING=1
FIO_TIME_BASED=1
FIO_SIZE=1G
REPETITIONS=2
COOLDOWN_SEC=5
