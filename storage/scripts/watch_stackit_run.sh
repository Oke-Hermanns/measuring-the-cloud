#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

RUN_ID=""
SCENARIO_FILE=""
IDLE_TIMEOUT_SEC=1800
POLL_SEC=60

usage() {
  cat >&2 <<USAGE
usage: $0 --run-id ID --scenario-file FILE [--idle-timeout-sec N] [--poll-sec N]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --scenario-file) SCENARIO_FILE="$2"; shift 2 ;;
    --idle-timeout-sec) IDLE_TIMEOUT_SEC="$2"; shift 2 ;;
    --poll-sec) POLL_SEC="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$RUN_ID" ]] || { usage; exit 1; }
[[ -n "$SCENARIO_FILE" ]] || { usage; exit 1; }

cd "$REPO_ROOT"
SCENARIO_FILE="$(abs_path "$SCENARIO_FILE")"
require_file "$SCENARIO_FILE"

RUN_DIR="${REPO_ROOT}/artifacts/storage/${RUN_ID}"
LAUNCHER_LOG="${RUN_DIR}/launcher.log"
WATCHDOG_LOG="${RUN_DIR}/watchdog.log"
require_file "$LAUNCHER_LOG"

touch "$WATCHDOG_LOG"
exec >>"$WATCHDOG_LOG" 2>&1

log "watchdog starting for run ${RUN_ID}"
log "scenario file: ${SCENARIO_FILE}"
log "idle timeout: ${IDLE_TIMEOUT_SEC}s poll interval: ${POLL_SEC}s"

unset SCENARIO_NAME PROVIDER TOFU_DIR TFVARS_FILE BENCHMARK_DIR OS_TUNING BENCHMARK_MACHINE_TYPE BENCHMARK_IMAGE_ID BLOCK_VOLUME_SIZE_GIB BLOCK_VOLUME_PERFORMANCE_CLASS BLOCK_VOLUME_TYPE BLOCK_VOLUME_IOPS BLOCK_VOLUME_THROUGHPUT_MBPS LOCAL_FILESYSTEM BLOCK_FILESYSTEM BENCHMARK_ROOT_VOLUME_SIZE_GIB BENCHMARK_ROOT_VOLUME_PERFORMANCE_CLASS SKIP SKIP_REASON
# shellcheck disable=SC1090
source "$SCENARIO_FILE"

TOFU_DIR="$(abs_path "$TOFU_DIR")"
TFVARS_FILE="$(abs_path "$TFVARS_FILE")"
require_dir "$TOFU_DIR"
require_file "$TFVARS_FILE"

BLOCK_VOLUME_SIZE_GIB="${BLOCK_VOLUME_SIZE_GIB:-0}"
BLOCK_VOLUME_PERFORMANCE_CLASS="${BLOCK_VOLUME_PERFORMANCE_CLASS:-}"
BLOCK_VOLUME_TYPE="${BLOCK_VOLUME_TYPE:-}"
BLOCK_VOLUME_IOPS="${BLOCK_VOLUME_IOPS:-}"
BLOCK_VOLUME_THROUGHPUT_MBPS="${BLOCK_VOLUME_THROUGHPUT_MBPS:-}"
LOCAL_FILESYSTEM="${LOCAL_FILESYSTEM:-raw}"
BLOCK_FILESYSTEM="${BLOCK_FILESYSTEM:-raw}"
BENCHMARK_ROOT_VOLUME_SIZE_GIB="${BENCHMARK_ROOT_VOLUME_SIZE_GIB:-30}"
BENCHMARK_ROOT_VOLUME_PERFORMANCE_CLASS="${BENCHMARK_ROOT_VOLUME_PERFORMANCE_CLASS:-}"

apply_tfvar_overlay() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp
  tmp="$(mktemp /tmp/cloud-measuring-watchdog-overlay.XXXXXX.tfvars)"

  awk -v key="$key" -v value="$value" '
    BEGIN { replaced = 0 }
    /^[[:space:]]*#/ { print; next }
    /^[[:space:]]*$/ { print; next }
    {
      line = $0
      trimmed = line
      sub(/^[[:space:]]+/, "", trimmed)
      candidate = trimmed
      sub(/[[:space:]]*=.*/, "", candidate)
      if (candidate == key) {
        if (!replaced) {
          printf "%s = %s\n", key, value
          replaced = 1
        }
        next
      }
      print
    }
    END {
      if (!replaced) {
        printf "%s = %s\n", key, value
      }
    }
  ' "$file" >"$tmp"

  mv "$tmp" "$file"
}

destroy_if_needed() {
  local merged_tfvars
  merged_tfvars="$(mktemp /tmp/cloud-measuring-watchdog-tfvars.XXXXXX.tfvars)"
  cp "$TFVARS_FILE" "$merged_tfvars"
  apply_tfvar_overlay "$merged_tfvars" "benchmark_machine_type" "\"${BENCHMARK_MACHINE_TYPE}\""
  apply_tfvar_overlay "$merged_tfvars" "benchmark_image_id" "\"${BENCHMARK_IMAGE_ID}\""
  apply_tfvar_overlay "$merged_tfvars" "benchmark_block_volume_size_gib" "${BLOCK_VOLUME_SIZE_GIB}"
  apply_tfvar_overlay "$merged_tfvars" "benchmark_block_volume_performance_class" "\"${BLOCK_VOLUME_PERFORMANCE_CLASS}\""
  [[ -n "$BLOCK_VOLUME_TYPE" ]] && apply_tfvar_overlay "$merged_tfvars" "benchmark_block_volume_type" "\"${BLOCK_VOLUME_TYPE}\""
  [[ -n "$BLOCK_VOLUME_IOPS" ]] && apply_tfvar_overlay "$merged_tfvars" "benchmark_block_volume_iops" "${BLOCK_VOLUME_IOPS}"
  [[ -n "$BLOCK_VOLUME_THROUGHPUT_MBPS" ]] && apply_tfvar_overlay "$merged_tfvars" "benchmark_block_volume_throughput_mbps" "${BLOCK_VOLUME_THROUGHPUT_MBPS}"
  apply_tfvar_overlay "$merged_tfvars" "benchmark_local_filesystem" "\"${LOCAL_FILESYSTEM}\""
  apply_tfvar_overlay "$merged_tfvars" "benchmark_block_filesystem" "\"${BLOCK_FILESYSTEM}\""
  apply_tfvar_overlay "$merged_tfvars" "benchmark_root_volume_size_gib" "${BENCHMARK_ROOT_VOLUME_SIZE_GIB}"
  apply_tfvar_overlay "$merged_tfvars" "benchmark_root_volume_performance_class" "\"${BENCHMARK_ROOT_VOLUME_PERFORMANCE_CLASS}\""

  log "watchdog invoking destroy for ${TOFU_DIR}"
  set +e
  "${SCRIPT_DIR}/destroy_infra.sh" --tofu-dir "$TOFU_DIR" --tfvars-file "$merged_tfvars"
  local rc=$?
  set -e
  rm -f "$merged_tfvars"
  log "watchdog destroy exit code: ${rc}"
  return "$rc"
}

last_mtime="$(stat -c %Y "$LAUNCHER_LOG")"

while true; do
  if rg -q "scenario .* completed" "$LAUNCHER_LOG"; then
    log "watchdog observed completed state; exiting"
    exit 0
  fi

  if rg -q "failed:" "$LAUNCHER_LOG"; then
    log "watchdog observed failed state"
    destroy_if_needed || true
    exit 0
  fi

  current_mtime="$(stat -c %Y "$LAUNCHER_LOG")"
  now="$(date +%s)"
  idle_for=$((now - current_mtime))

  if (( current_mtime != last_mtime )); then
    log "watchdog observed launcher activity; idle reset"
    last_mtime="$current_mtime"
  elif (( idle_for > IDLE_TIMEOUT_SEC )); then
    log "watchdog observed idle timeout (${idle_for}s); forcing destroy"
    destroy_if_needed || true
    exit 0
  fi

  sleep "$POLL_SEC"
done
