#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

RUNNER_HOST=""
SSH_KEY=""
SSH_USER="ubuntu"
RUN_ID=""
WORKLOAD="auto"
LOCAL_OUT=""
REMOTE_RESULTS_ROOT="/opt/cloud-measuring/artifacts"

usage() {
  cat >&2 <<USAGE
usage: $0 [--workload auto|network|storage] --runner-host HOST --ssh-key PATH [--run-id ID] [--ssh-user ubuntu] [--out artifacts/<workload>] [--results-root /opt/cloud-measuring/artifacts]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workload) WORKLOAD="$2"; shift 2 ;;
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
require_file "$(expand_home "$SSH_KEY")"

case "$WORKLOAD" in
  auto|network|storage) ;;
  *) die "--workload must be one of: auto, network, storage" ;;
esac

SSH_KEY="$(expand_home "$SSH_KEY")"
cd "$REPO_ROOT"
KNOWN_HOSTS_FILE="$(mktemp /tmp/cloud-measuring-known-hosts.XXXXXX)"
trap 'rm -f "$KNOWN_HOSTS_FILE"' EXIT

ssh_run() {
  local cmd="$1"
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR -o UserKnownHostsFile="$KNOWN_HOSTS_FILE" "${SSH_USER}@${RUNNER_HOST}" "$cmd"
}

resolve_remote_run_path() {
  local search_root="$1"
  local query_run_id="${2:-}"
  if [[ -n "$query_run_id" ]]; then
    ssh_run "find $(printf '%q' "$search_root") -type d -name $(printf '%q' "$query_run_id") | grep -v '/runner-control/' | sort | tail -n 1"
  else
    ssh_run "find $(printf '%q' "$search_root") -type d -name 'run-*' -printf '%f\t%p\n' | grep -v '/runner-control/' | sort | tail -n 1 | cut -f2-"
  fi
}

search_root="$REMOTE_RESULTS_ROOT"
if [[ "$WORKLOAD" != "auto" && "$(basename "$search_root")" != "$WORKLOAD" ]]; then
  search_root="${search_root%/}/${WORKLOAD}"
fi

REMOTE_RUN_PATH="$(resolve_remote_run_path "$search_root" "$RUN_ID")"
[[ -n "$REMOTE_RUN_PATH" ]] || die "no matching results found under ${search_root}"

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(basename "$REMOTE_RUN_PATH")"
fi
if [[ "$WORKLOAD" == "auto" ]]; then
  WORKLOAD="$(basename "$(dirname "$REMOTE_RUN_PATH")")"
fi

if [[ -z "$LOCAL_OUT" ]]; then
  LOCAL_OUT="artifacts/${WORKLOAD}"
fi
LOCAL_OUT="$(abs_path "$LOCAL_OUT")"

mkdir -p "$LOCAL_OUT"

LOCAL_RUN_DIR="${LOCAL_OUT}/${RUN_ID}"
mkdir -p "$LOCAL_RUN_DIR"

SSH_REMOTE_CMD="ssh -i ${SSH_KEY@Q} -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR -o UserKnownHostsFile=${KNOWN_HOSTS_FILE@Q}"

log "fetching results from runner ${RUNNER_HOST}"
rsync -az -e "$SSH_REMOTE_CMD" \
  "${SSH_USER}@${RUNNER_HOST}:${REMOTE_RUN_PATH}/" \
  "${LOCAL_RUN_DIR}/"

log "results downloaded to ${LOCAL_RUN_DIR}"
