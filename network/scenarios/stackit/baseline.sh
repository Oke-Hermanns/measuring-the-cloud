SCENARIO_NAME=stackit-baseline
PROVIDER=stackit
TOFU_DIR=network/infra/stackit
TFVARS_FILE=network/scenarios/stackit/baseline.tfvars
BENCHMARK_DIR=network/benchmarks/baseline
OS_TUNING=standard
INSTANCE_AFFINITY=different-host

# Metadata only for now. Concrete placement is controlled through the tfvars file.
PLACEMENT_MODE=single-az
