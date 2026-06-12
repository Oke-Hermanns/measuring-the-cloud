source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../common.inc"

SCENARIO_NAME=aws_c6id.large_ebs-gp3_standard
BENCHMARK_MACHINE_TYPE=c6id.large
BLOCK_VOLUME_SIZE_GIB=100
