#!/usr/bin/env bash
set -euo pipefail

ROLE=""
PROTOCOL="udp"
MODE="pp"
SERVER_IP=""
PORT="11111"
MSG_SIZE="64"
RUNTIME_SEC="10"
OUT_DIR=""
CPU_LIST=""

default_cpu_list() {
  local n
  n="$(nproc 2>/dev/null || echo 1)"
  if [[ "$n" =~ ^[0-9]+$ && "$n" -ge 2 ]]; then
    echo "1-$((n - 1))"
  else
    echo "0"
  fi
}

usage() {
  cat >&2 <<USAGE
usage: $0 --role server|client [--protocol tcp|udp] [--mode pp] [--server-ip IP] [--port N] [--msg-size N] [--runtime-sec N] [--out-dir PATH] [--cpu-list LIST]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="$2"; shift 2 ;;
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --server-ip) SERVER_IP="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --msg-size) MSG_SIZE="$2"; shift 2 ;;
    --runtime-sec) RUNTIME_SEC="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --cpu-list) CPU_LIST="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ "$ROLE" == "server" || "$ROLE" == "client" ]] || { usage; exit 1; }
[[ "$PROTOCOL" == "tcp" || "$PROTOCOL" == "udp" ]] || { echo "--protocol must be tcp or udp" >&2; exit 1; }
[[ "$MODE" == "pp" ]] || { echo "only sockperf pp mode is currently supported" >&2; exit 1; }
command -v sockperf >/dev/null 2>&1 || { echo "sockperf not found" >&2; exit 1; }
command -v taskset >/dev/null 2>&1 || { echo "taskset not found" >&2; exit 1; }
CPU_LIST="${CPU_LIST:-$(default_cpu_list)}"

proto_args=()
if [[ "$PROTOCOL" == "tcp" ]]; then
  proto_args+=(--tcp)
fi

if [[ "$ROLE" == "server" ]]; then
  exec taskset -c "$CPU_LIST" sockperf server "${proto_args[@]}" --ip 0.0.0.0 --port "$PORT"
fi

[[ -n "$SERVER_IP" ]] || { echo "--server-ip is required for client role" >&2; exit 1; }
[[ -n "$OUT_DIR" ]] || { echo "--out-dir is required for client role" >&2; exit 1; }
mkdir -p "$OUT_DIR"

cmd=(taskset -c "$CPU_LIST" sockperf pp "${proto_args[@]}" --ip "$SERVER_IP" --port "$PORT" --msg-size "$MSG_SIZE" --time "$RUNTIME_SEC" --full-rtt)

printf '%q' "${cmd[0]}" >"${OUT_DIR}/client.cmd"
for arg in "${cmd[@]:1}"; do
  printf ' %q' "$arg" >>"${OUT_DIR}/client.cmd"
done
printf '\n' >>"${OUT_DIR}/client.cmd"

set +e
"${cmd[@]}" >"${OUT_DIR}/sockperf.log" 2>&1
rc=$?
set -e
exit "$rc"
