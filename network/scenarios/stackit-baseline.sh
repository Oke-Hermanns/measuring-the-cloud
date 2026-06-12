#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/stackit/baseline.sh"
if [[ -f network/scenarios/stackit-baseline.tfvars ]]; then
  TFVARS_FILE=network/scenarios/stackit-baseline.tfvars
fi
