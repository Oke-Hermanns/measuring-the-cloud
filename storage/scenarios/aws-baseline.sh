#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/aws/baseline.sh"
if [[ -f storage/scenarios/aws-baseline.tfvars ]]; then
  TFVARS_FILE=storage/scenarios/aws-baseline.tfvars
fi
