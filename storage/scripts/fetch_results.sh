#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

TOFU_DIR=""
SCENARIO_NAME=""
RUN_ID=""
LOCAL_OUT="artifacts/storage"
REMOTE_RESULTS_ROOT="/opt/cloud-measuring/results"
ACCESS_MODE="private"

usage() {
  cat >&2 <<USAGE
usage: $0 --tofu-dir PATH --scenario-name NAME --run-id ID [--out artifacts/storage] [--results-root /opt/cloud-measuring/results] [--access-mode public|private]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tofu-dir) TOFU_DIR="$2"; shift 2 ;;
    --scenario-name) SCENARIO_NAME="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --out) LOCAL_OUT="$2"; shift 2 ;;
    --results-root) REMOTE_RESULTS_ROOT="$2"; shift 2 ;;
    --access-mode) ACCESS_MODE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$TOFU_DIR" ]] || { usage; exit 1; }
[[ -n "$SCENARIO_NAME" ]] || { usage; exit 1; }
[[ -n "$RUN_ID" ]] || { usage; exit 1; }
case "$ACCESS_MODE" in
  public|private) ;;
  *) die "--access-mode must be one of: public, private" ;;
esac

cd "$REPO_ROOT"
TOFU_DIR="$(abs_path "$TOFU_DIR")"
LOCAL_OUT="$(abs_path "$LOCAL_OUT")"
require_dir "$TOFU_DIR"

tofu="$(tofu_bin)"
BENCHMARK_PRIVATE_IP="$(tofu_output_raw "$tofu" "$TOFU_DIR" benchmark_private_ip)"
SSH_KEY="$(expand_home "$(tofu_output_raw "$tofu" "$TOFU_DIR" ssh_private_key_path)")"
SSH_USER="$(tofu_output_raw "$tofu" "$TOFU_DIR" benchmark_ssh_user)"
require_file "$SSH_KEY"

if [[ "$ACCESS_MODE" == "private" ]]; then
  BENCHMARK_HOST="$BENCHMARK_PRIVATE_IP"
else
  BENCHMARK_HOST="$(tofu_output_raw "$tofu" "$TOFU_DIR" benchmark_public_ip)"
fi

LOCAL_SCENARIO_DIR="${LOCAL_OUT}/${RUN_ID}/${SCENARIO_NAME}"
REMOTE_SCENARIO_DIR="${REMOTE_RESULTS_ROOT}/${RUN_ID}/${SCENARIO_NAME}"
mkdir -p "${LOCAL_SCENARIO_DIR}"
KNOWN_HOSTS_FILE="${LOCAL_OUT}/${RUN_ID}/known_hosts"
if [[ ! -f "$KNOWN_HOSTS_FILE" ]]; then
  : >"$KNOWN_HOSTS_FILE"
fi

SSH_REMOTE_CMD="$(ssh_base_cmd "$SSH_KEY" "$KNOWN_HOSTS_FILE")"

ssh_run() {
  local cmd="$1"
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR -o UserKnownHostsFile="$KNOWN_HOSTS_FILE" "${SSH_USER}@${BENCHMARK_HOST}" "$cmd"
}

log "fetching results from benchmark host ${BENCHMARK_HOST}"
if ssh_run "test -d $(printf '%q' "$REMOTE_SCENARIO_DIR")"; then
  rsync -az -e "${SSH_REMOTE_CMD}" \
    "${SSH_USER}@${BENCHMARK_HOST}:${REMOTE_SCENARIO_DIR}/" \
    "${LOCAL_SCENARIO_DIR}/"
else
  log "remote scenario directory missing; fetching bootstrap logs instead"
  mkdir -p "${LOCAL_SCENARIO_DIR}/bootstrap-failure"
  rsync -az -e "${SSH_REMOTE_CMD}" \
    --ignore-missing-args \
    "${SSH_USER}@${BENCHMARK_HOST}:/var/log/cloud-init.log" \
    "${SSH_USER}@${BENCHMARK_HOST}:/var/log/cloud-init-output.log" \
    "${SSH_USER}@${BENCHMARK_HOST}:/var/log/cloud-measuring-user-data.log" \
    "${SSH_USER}@${BENCHMARK_HOST}:/tmp/cloud-init-status.log" \
    "${LOCAL_SCENARIO_DIR}/bootstrap-failure/" || true
fi

log "results downloaded to ${LOCAL_SCENARIO_DIR}"
