#!/usr/bin/env bash
set -euo pipefail

ROLE=""
PROTOCOL="tcp"
SERVER_IP=""
PORT="5201"
RUNTIME_SEC="10"
OMIT_SEC="1"
PARALLEL="1"
TCP_LENGTH="128K"
UDP_BITRATE="100M"
UDP_LENGTH="1200"
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
usage: $0 --role server|client [--protocol tcp|udp] [--server-ip IP] [--port N] [--runtime-sec N] [--omit-sec N] [--parallel N] [--tcp-length LEN] [--udp-bitrate RATE] [--udp-length N] [--out-dir PATH] [--cpu-list LIST]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="$2"; shift 2 ;;
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --server-ip) SERVER_IP="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --runtime-sec) RUNTIME_SEC="$2"; shift 2 ;;
    --omit-sec) OMIT_SEC="$2"; shift 2 ;;
    --parallel) PARALLEL="$2"; shift 2 ;;
    --tcp-length) TCP_LENGTH="$2"; shift 2 ;;
    --udp-bitrate) UDP_BITRATE="$2"; shift 2 ;;
    --udp-length) UDP_LENGTH="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --cpu-list) CPU_LIST="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ "$ROLE" == "server" || "$ROLE" == "client" ]] || { usage; exit 1; }
[[ "$PROTOCOL" == "tcp" || "$PROTOCOL" == "udp" ]] || { echo "--protocol must be tcp or udp" >&2; exit 1; }
command -v iperf3 >/dev/null 2>&1 || { echo "iperf3 not found" >&2; exit 1; }
command -v taskset >/dev/null 2>&1 || { echo "taskset not found" >&2; exit 1; }
CPU_LIST="${CPU_LIST:-$(default_cpu_list)}"

if [[ "$ROLE" == "server" ]]; then
  exec taskset -c "$CPU_LIST" iperf3 -s -p "$PORT" -1
fi

[[ -n "$SERVER_IP" ]] || { echo "--server-ip is required for client role" >&2; exit 1; }
[[ -n "$OUT_DIR" ]] || { echo "--out-dir is required for client role" >&2; exit 1; }
mkdir -p "$OUT_DIR"

cmd=(taskset -c "$CPU_LIST" iperf3 -c "$SERVER_IP" -p "$PORT" -t "$RUNTIME_SEC" -O "$OMIT_SEC" -P "$PARALLEL" -l "$TCP_LENGTH" -J --get-server-output)
if [[ "$PROTOCOL" == "udp" ]]; then
  cmd+=(-u -b "$UDP_BITRATE" -l "$UDP_LENGTH" --udp-counters-64)
fi

printf '%q' "${cmd[0]}" >"${OUT_DIR}/client.cmd"
for arg in "${cmd[@]:1}"; do
  printf ' %q' "$arg" >>"${OUT_DIR}/client.cmd"
done
printf '\n' >>"${OUT_DIR}/client.cmd"

"${cmd[@]}" >"${OUT_DIR}/iperf3.json" 2>"${OUT_DIR}/iperf3.log"
