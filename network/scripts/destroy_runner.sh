#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

TOFU_DIR="network/infra/stackit-runner"
TFVARS_FILE="network/infra/stackit-runner/basic-infra.tfvars"

usage() {
  cat >&2 <<USAGE
usage: $0 [--tofu-dir PATH] [--tfvars-file PATH]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tofu-dir) TOFU_DIR="$2"; shift 2 ;;
    --tfvars-file) TFVARS_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

cd "$REPO_ROOT"
TOFU_DIR="$(abs_path "$TOFU_DIR")"
TFVARS_FILE="$(abs_path "$TFVARS_FILE")"
require_dir "$TOFU_DIR"
require_file "$TFVARS_FILE"

"${SCRIPT_DIR}/destroy_infra.sh" --tofu-dir "$TOFU_DIR" --tfvars-file "$TFVARS_FILE"
