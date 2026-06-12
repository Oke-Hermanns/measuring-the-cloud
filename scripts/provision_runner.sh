#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/common/scripts/common.sh"

declare -a SCENARIO_FILES=()
declare -a BENCHMARK_NAMES=()
SCENARIO_DIR=""
WORKLOAD=""
DESTROY_MODE="always"
CONTINUE_ON_ERROR=0
RUN_ID="run-$(date +%Y%m%d-%H%M%S)"
LOCAL_OUT=""
RUNNER_WORKDIR="/opt/cloud-measuring"
BASIC_TOFU_DIR="infra/stackit-runner"
BASIC_TFVARS_FILE="infra/stackit-runner/basic-infra.tfvars"
SERVICE_ACCOUNT_JSON=""
ACCESS_MODE="private"

usage() {
  cat >&2 <<USAGE
usage: $0 [--workload network|storage] [--scenario FILE ... | --scenario-dir DIR] [--benchmark NAME ...] [--destroy always|success|never] [--continue-on-error] --service-account-json PATH [--basic-tofu-dir DIR] [--basic-tfvars-file FILE] [--run-id ID]
USAGE
}

infer_workload_from_path() {
  local path="$1"
  local rel="${path#${REPO_ROOT}/}"
  local prefix="${rel%%/*}"
  [[ "$prefix" != "$rel" ]] || return 1
  printf '%s\n' "$prefix"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workload) WORKLOAD="$2"; shift 2 ;;
    --scenario) SCENARIO_FILES+=("$2"); shift 2 ;;
    --scenario-dir) SCENARIO_DIR="$2"; shift 2 ;;
    --benchmark) BENCHMARK_NAMES+=("$2"); shift 2 ;;
    --destroy) DESTROY_MODE="$2"; shift 2 ;;
    --continue-on-error) CONTINUE_ON_ERROR=1; shift ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --out) LOCAL_OUT="$2"; shift 2 ;;
    --runner-workdir) RUNNER_WORKDIR="$2"; shift 2 ;;
    --basic-tofu-dir) BASIC_TOFU_DIR="$2"; shift 2 ;;
    --basic-tfvars-file) BASIC_TFVARS_FILE="$2"; shift 2 ;;
    --service-account-json) SERVICE_ACCOUNT_JSON="$2"; shift 2 ;;
    --access-mode) ACCESS_MODE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

case "$DESTROY_MODE" in
  always|success|never) ;;
  *) die "--destroy must be one of: always, success, never" ;;
esac
case "$ACCESS_MODE" in
  private|public) ;;
  *) die "--access-mode must be one of: public, private" ;;
esac
[[ "$ACCESS_MODE" == "private" ]] || die "runner provisioning currently requires --access-mode private"
[[ -n "$SERVICE_ACCOUNT_JSON" ]] || { usage; exit 1; }

cd "$REPO_ROOT"
BASIC_TOFU_DIR="$(abs_path "$BASIC_TOFU_DIR")"
BASIC_TFVARS_FILE="$(abs_path "$BASIC_TFVARS_FILE")"
SERVICE_ACCOUNT_JSON="$(abs_path "$SERVICE_ACCOUNT_JSON")"
require_dir "$BASIC_TOFU_DIR"
require_file "$BASIC_TFVARS_FILE"
require_file "$SERVICE_ACCOUNT_JSON"

if [[ -n "$SCENARIO_DIR" ]]; then
  SCENARIO_DIR="$(abs_path "$SCENARIO_DIR")"
  require_dir "$SCENARIO_DIR"
  mapfile -t dir_scenarios < <(find "$SCENARIO_DIR" -type f -name '*.sh' | sort)
  for scenario in "${dir_scenarios[@]}"; do
    SCENARIO_FILES+=("${scenario#${REPO_ROOT}/}")
  done
fi

if [[ "${#SCENARIO_FILES[@]}" -eq 0 ]]; then
  SCENARIO_FILES+=("network/scenarios/stackit/baseline.sh")
fi

if [[ -z "$WORKLOAD" ]]; then
  infer_source=""
  if [[ -n "$SCENARIO_DIR" ]]; then
    infer_source="$SCENARIO_DIR"
  else
    infer_source="${SCENARIO_FILES[0]}"
  fi
  infer_source="$(abs_path "$infer_source")"
  WORKLOAD="$(infer_workload_from_path "$infer_source")" || die "unable to infer workload from path: $infer_source"
fi

case "$WORKLOAD" in
  network|storage) ;;
  *) die "--workload must be one of: network, storage" ;;
esac

if [[ "${#SCENARIO_FILES[@]}" -gt 0 ]]; then
  for scenario in "${SCENARIO_FILES[@]}"; do
    scenario="$(abs_path "$scenario")"
    [[ "$scenario" == "$REPO_ROOT/"* ]] || die "scenario file must live under the repository root: $scenario"
    scenario_workload="$(infer_workload_from_path "$scenario")" || die "unable to infer workload from scenario path: $scenario"
    [[ "$scenario_workload" == "$WORKLOAD" ]] || die "all scenarios must belong to the same workload prefix; saw ${scenario_workload} and ${WORKLOAD}"
  done
fi

if [[ -z "$LOCAL_OUT" ]]; then
  LOCAL_OUT="artifacts/${WORKLOAD}"
fi

LOCAL_OUT="$(abs_path "$LOCAL_OUT")"
LOCAL_RUN_DIR="${LOCAL_OUT}/runner-control/${RUN_ID}"
mkdir -p "$LOCAL_RUN_DIR"
LOCAL_LAUNCHER_LOG="${LOCAL_RUN_DIR}/launcher.log"
LOCAL_COMMAND_LOG="${LOCAL_RUN_DIR}/commands.log"
: >"$LOCAL_LAUNCHER_LOG"
: >"$LOCAL_COMMAND_LOG"
exec > >(tee -a "$LOCAL_LAUNCHER_LOG") 2>&1
log "launcher log: ${LOCAL_LAUNCHER_LOG}"
log "command log: ${LOCAL_COMMAND_LOG}"
log "run id: ${RUN_ID}"
log "workload: ${WORKLOAD}"

tofu="$(tofu_bin)"
SSH_REMOTE_CMD=""
KNOWN_HOSTS_FILE="${LOCAL_RUN_DIR}/known_hosts"
: >"$KNOWN_HOSTS_FILE"

log "provisioning runner foundation in ${BASIC_TOFU_DIR}"
STACKIT_SERVICE_ACCOUNT_KEY_PATH="$SERVICE_ACCOUNT_JSON" \
  "${REPO_ROOT}/scripts/setup_infra.sh" \
    --tofu-dir "$BASIC_TOFU_DIR" \
    --tfvars-file "$BASIC_TFVARS_FILE"

RUNNER_PUBLIC_IP="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" runner_public_ip)"
RUNNER_PRIVATE_IP="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" runner_private_ip)"
RUNNER_SSH_KEY="$(expand_home "$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" ssh_private_key_path)")"
RUNNER_SSH_USER="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" ssh_user)"
STACKIT_PROJECT_ID="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" stackit_project_id)"
STACKIT_REGION="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" stackit_region)"
SUBNET_CIDR="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" subnet_cidr)"
IMAGE_ID="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" image_id)"
NETWORK_ID="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" network_id)"
SECURITY_GROUP_ID="$(tofu_output_raw "$tofu" "$BASIC_TOFU_DIR" security_group_id)"

SSH_REMOTE_CMD="$(ssh_base_cmd "$RUNNER_SSH_KEY" "$KNOWN_HOSTS_FILE")"

runner_ssh() {
  local host="$1"
  shift
  local -a ssh_opts
  mapfile -t ssh_opts < <(ssh_base_args "$RUNNER_SSH_KEY" "$KNOWN_HOSTS_FILE")
  local cmd
  cmd=(ssh "${ssh_opts[@]}" "${RUNNER_SSH_USER}@${host}" "$@")
  append_command_log "$LOCAL_COMMAND_LOG" "${cmd[@]}"
  "${cmd[@]}"
}

runner_scp() {
  local src="$1"
  local host="$2"
  local dst="$3"
  local -a scp_opts
  mapfile -t scp_opts < <(ssh_base_args "$RUNNER_SSH_KEY" "$KNOWN_HOSTS_FILE")
  local cmd
  cmd=(scp "${scp_opts[@]}" "$src" "${RUNNER_SSH_USER}@${host}:${dst}")
  append_command_log "$LOCAL_COMMAND_LOG" "${cmd[@]}"
  "${cmd[@]}"
}

wait_for_runner_host() {
  local attempt
  log "waiting for runner SSH to be ready"
  for attempt in $(seq 1 90); do
    if runner_ssh "$RUNNER_PUBLIC_IP" "true" >/dev/null 2>&1; then
      log "runner SSH is ready"
      return 0
    fi
    if (( attempt % 10 == 0 )); then
      log "still waiting for runner SSH to be ready (${attempt}/90 attempts)"
    fi
    sleep 2
  done
  die "runner SSH did not become ready: ${RUNNER_PUBLIC_IP}"
}

wait_for_runner_cloud_init() {
  local attempt
  log "waiting for runner cloud-init to finish"
  for attempt in $(seq 1 180); do
    if runner_ssh "$RUNNER_PUBLIC_IP" "cloud-init status 2>/dev/null | grep -Eq 'status: done|status: error'"; then
      break
    fi
    if (( attempt % 10 == 0 )); then
      log "still waiting for runner cloud-init to finish (${attempt}/180 attempts)"
    fi
    sleep 2
  done
  runner_ssh "$RUNNER_PUBLIC_IP" "cloud-init status --wait >/tmp/cloud-init-status.log 2>&1 || (cat /tmp/cloud-init-status.log; exit 1)"
}

wait_for_runner_host
wait_for_runner_cloud_init

log "syncing repository assets to the runner"
rsync -az --delete -e "$SSH_REMOTE_CMD" \
  --include '/README.md' \
  --include '/common/' \
  --include '/common/***' \
  --include "/${WORKLOAD}/" \
  --include "/${WORKLOAD}/***" \
  --include '/scripts/' \
  --include '/scripts/***' \
  --exclude "/${WORKLOAD}/**/.terraform/" \
  --exclude "/${WORKLOAD}/**/terraform.tfstate*" \
  --exclude "/${WORKLOAD}/**/artifacts/" \
  --exclude "/${WORKLOAD}/**/logs/" \
  --exclude "/${WORKLOAD}/**/state/" \
  --exclude "/${WORKLOAD}/**/*.tfvars" \
  --exclude "/${WORKLOAD}/**/*.tfvars.json" \
  --exclude '*' \
  "${REPO_ROOT}/" \
  "${RUNNER_SSH_USER}@${RUNNER_PUBLIC_IP}:${RUNNER_WORKDIR}/"

log "copying service account key to the runner"
runner_ssh "$RUNNER_PUBLIC_IP" "mkdir -p '${RUNNER_WORKDIR}/state' '${RUNNER_WORKDIR}/bin' '${RUNNER_WORKDIR}/artifacts/${WORKLOAD}' '${RUNNER_WORKDIR}/repo'"
runner_scp "$SERVICE_ACCOUNT_JSON" "$RUNNER_PUBLIC_IP" "${RUNNER_WORKDIR}/state/stackit-service-account.json"
runner_ssh "$RUNNER_PUBLIC_IP" "chmod 600 '${RUNNER_WORKDIR}/state/stackit-service-account.json'"

REMOTE_BENCH_KEY="${RUNNER_WORKDIR}/state/benchmark_ssh_key"
runner_ssh "$RUNNER_PUBLIC_IP" "if [[ ! -f '${REMOTE_BENCH_KEY}' ]]; then ssh-keygen -t ed25519 -N '' -f '${REMOTE_BENCH_KEY}' >/dev/null; fi; chmod 600 '${REMOTE_BENCH_KEY}' '${REMOTE_BENCH_KEY}.pub'"

REMOTE_BASELINE_TFVARS="${RUNNER_WORKDIR}/${WORKLOAD}/scenarios/stackit/baseline.tfvars"
REMOTE_SSH_INGRESS_CIDR="${RUNNER_PUBLIC_IP}/32"

tmp_tfvars="$(mktemp /tmp/cloud-measuring-runner-baseline.XXXXXX.tfvars)"
  case "$WORKLOAD" in
    network)
    cat >"$tmp_tfvars" <<EOF
stackit_project_id = "${STACKIT_PROJECT_ID}"
stackit_region = "${STACKIT_REGION}"
subnet_cidr = "${SUBNET_CIDR}"
client_availability_zone = "eu01-1"
server_availability_zone = "eu01-1"
client_machine_type = "g2a.2d"
server_machine_type = "g2a.2d"
image_id = "${IMAGE_ID}"
ssh_public_key_path = "${REMOTE_BENCH_KEY}.pub"
ssh_private_key_path = "${REMOTE_BENCH_KEY}"
existing_network_id = "${NETWORK_ID}"
existing_security_group_id = "${SECURITY_GROUP_ID}"
ssh_ingress_cidr = "${REMOTE_SSH_INGRESS_CIDR}"
ipv4_nameservers = ["1.1.1.1", "8.8.8.8"]
assign_public_ip = false
instance_affinity = "none"
root_volume_size_gib = 30
root_volume_performance_class = ""
EOF
    ;;
    storage)
      cat >"$tmp_tfvars" <<EOF
stackit_project_id = "${STACKIT_PROJECT_ID}"
stackit_region = "${STACKIT_REGION}"
subnet_cidr = "${SUBNET_CIDR}"
ssh_public_key_path = "${REMOTE_BENCH_KEY}.pub"
ssh_private_key_path = "${REMOTE_BENCH_KEY}"
existing_network_id = "${NETWORK_ID}"
existing_security_group_id = "${SECURITY_GROUP_ID}"
ssh_ingress_cidr = "${REMOTE_SSH_INGRESS_CIDR}"
ipv4_nameservers = ["1.1.1.1", "8.8.8.8"]
assign_public_ip = false
benchmark_root_volume_size_gib = 30
benchmark_root_volume_performance_class = ""
EOF
      ;;
  *)
    die "unsupported workload: ${WORKLOAD}"
    ;;
esac
runner_scp "$tmp_tfvars" "$RUNNER_PUBLIC_IP" "$REMOTE_BASELINE_TFVARS"
rm -f "$tmp_tfvars"

remote_runner_args=()
for scenario in "${SCENARIO_FILES[@]}"; do
  scenario="$(abs_path "$scenario")"
  [[ "$scenario" == "$REPO_ROOT/"* ]] || die "scenario file must live under the repository root: $scenario"
  remote_runner_args+=(--scenario "${scenario#${REPO_ROOT}/}")
done
for benchmark in "${BENCHMARK_NAMES[@]}"; do
  remote_runner_args+=(--benchmark "$benchmark")
done

log "starting detached benchmark run on the runner"
runner_ssh "$RUNNER_PUBLIC_IP" "cd '${RUNNER_WORKDIR}' && bash ./scripts/launch_runner_job.sh --workload '${WORKLOAD}' --run-id '${RUN_ID}' --destroy '${DESTROY_MODE}' --access-mode private -- $(shell_join "${remote_runner_args[@]}")"

log "runner public ip: ${RUNNER_PUBLIC_IP}"
log "runner private ip: ${RUNNER_PRIVATE_IP}"
log "status command:"
echo "ssh -i '${RUNNER_SSH_KEY}' ${RUNNER_SSH_USER}@${RUNNER_PUBLIC_IP} \"tail -f '${RUNNER_WORKDIR}/artifacts/${WORKLOAD}/${RUN_ID}/launcher.log'\""
log "fetch command:"
echo "${SCRIPT_DIR}/fetch_runner_results.sh --workload ${WORKLOAD} --runner-host ${RUNNER_PUBLIC_IP} --ssh-key '${RUNNER_SSH_KEY}' --run-id '${RUN_ID}' --out '${LOCAL_OUT}'"
