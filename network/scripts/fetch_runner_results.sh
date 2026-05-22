#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

RUNNER_HOST=""
SSH_KEY=""
SSH_USER="ubuntu"
RUN_ID=""
LOCAL_OUT="artifacts/network"
REMOTE_RESULTS_ROOT="/opt/cloud-measuring/artifacts/network"

usage() {
  cat >&2 <<USAGE
usage: $0 --runner-host HOST --ssh-key PATH --run-id ID [--ssh-user ubuntu] [--out artifacts/network] [--results-root /opt/cloud-measuring/artifacts/network]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runner-host) RUNNER_HOST="$2"; shift 2 ;;
    --ssh-key) SSH_KEY="$2"; shift 2 ;;
    --ssh-user) SSH_USER="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --out) LOCAL_OUT="$2"; shift 2 ;;
    --results-root) REMOTE_RESULTS_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$RUNNER_HOST" ]] || { usage; exit 1; }
[[ -n "$SSH_KEY" ]] || { usage; exit 1; }
[[ -n "$RUN_ID" ]] || { usage; exit 1; }
require_file "$(expand_home "$SSH_KEY")"

SSH_KEY="$(expand_home "$SSH_KEY")"
cd "$REPO_ROOT"
LOCAL_OUT="$(abs_path "$LOCAL_OUT")"
mkdir -p "${LOCAL_OUT}/${RUN_ID}"

KNOWN_HOSTS_FILE="${LOCAL_OUT}/${RUN_ID}/known_hosts"
: >"$KNOWN_HOSTS_FILE"
SSH_REMOTE_CMD="$(ssh_base_cmd "$SSH_KEY" "$KNOWN_HOSTS_FILE")"

log "fetching results from runner ${RUNNER_HOST}"
rsync -az -e "$SSH_REMOTE_CMD" \
  "${SSH_USER}@${RUNNER_HOST}:${REMOTE_RESULTS_ROOT}/${RUN_ID}/" \
  "${LOCAL_OUT}/${RUN_ID}/"

log "results downloaded to ${LOCAL_OUT}/${RUN_ID}"
