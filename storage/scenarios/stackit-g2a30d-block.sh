#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/stackit/g2a30d-block.sh"
if [[ -f storage/scenarios/stackit-baseline.tfvars ]]; then
  TFVARS_FILE=storage/scenarios/stackit-baseline.tfvars
fi
