#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

RUNNER_WORKDIR="${RUNNER_WORKDIR:-/opt/cloud-measuring}"
WORKLOAD=""
RUN_ID=""
DESTROY_MODE="always"
ACCESS_MODE="private"
declare -a RUNNER_ARGS=()

usage() {
  cat >&2 <<USAGE
usage: $0 --workload WORKLOAD --run-id ID [--destroy always|success|never] [--access-mode public|private] -- [runner args...]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workload) WORKLOAD="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --destroy) DESTROY_MODE="$2"; shift 2 ;;
    --access-mode) ACCESS_MODE="$2"; shift 2 ;;
    --) shift; RUNNER_ARGS=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$WORKLOAD" ]] || { usage; exit 1; }
[[ -n "$RUN_ID" ]] || { usage; exit 1; }
case "$DESTROY_MODE" in
  always|success|never) ;;
  *) die "--destroy must be one of: always, success, never" ;;
esac
case "$ACCESS_MODE" in
  public|private) ;;
  *) die "--access-mode must be one of: public, private" ;;
esac

ARTIFACT_DIR="${RUNNER_WORKDIR}/artifacts/${WORKLOAD}/${RUN_ID}"
STATE_DIR="${RUNNER_WORKDIR}/state"
PID_FILE="${STATE_DIR}/runner-${RUN_ID}.pid"
LAUNCHER_LOG="${ARTIFACT_DIR}/launcher.log"

mkdir -p "$ARTIFACT_DIR" "$STATE_DIR"

runner_cmd=(
  env
  PATH="/usr/local/bin:/usr/bin:/bin"
  STACKIT_SERVICE_ACCOUNT_KEY_PATH="${STATE_DIR}/stackit-service-account.json"
  "./${WORKLOAD}/runner.sh"
  --access-mode "$ACCESS_MODE"
  --run-id "$RUN_ID"
  --destroy "$DESTROY_MODE"
  "${RUNNER_ARGS[@]}"
)

(
  cd "$RUNNER_WORKDIR"
  nohup "${runner_cmd[@]}" >"$LAUNCHER_LOG" 2>&1 < /dev/null &
  printf '%s\n' "$!" >"$PID_FILE"
)

printf 'launched workload=%s run-id=%s pid=%s launcher-log=%s\n' "$WORKLOAD" "$RUN_ID" "$(cat "$PID_FILE")" "$LAUNCHER_LOG"
printf '%s\n' "$PID_FILE"
