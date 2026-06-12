SCENARIO_NAME=aws-baseline
PROVIDER=aws
TOFU_DIR=network/infra/aws
TFVARS_FILE=network/scenarios/aws/baseline.tfvars
BENCHMARK_DIR=network/benchmarks/baseline
OS_TUNING=standard
INSTANCE_AFFINITY=none

# Metadata only for now. Concrete placement is controlled through the tfvars file.
PLACEMENT_MODE=single-az
