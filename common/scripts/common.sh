#!/usr/bin/env bash

die() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  cd -- "${script_dir}/../.." && pwd
}

abs_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$(pwd)" "$path"
  fi
}

expand_home() {
  local path="$1"
  printf '%s\n' "${path/#\~/$HOME}"
}

write_env_file() {
  local path="$1"
  shift

  {
    echo "#!/usr/bin/env bash"
    local name
    for name in "$@"; do
      if [[ ${!name+x} ]]; then
        printf 'export %s=%q\n' "$name" "${!name}"
      fi
    done
  } >"$path"
}

append_command_text() {
  local log_file="$1"
  local env_file="$2"
  local text="$3"

  {
    printf '# %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ -n "$env_file" ]]; then
      printf 'source %q\n' "$env_file"
    fi
    printf '%s\n\n' "$text"
  } >>"$log_file"
}

append_command_log() {
  local log_file="$1"
  shift

  local env_file=""
  if [[ "${1:-}" == "--env-file" ]]; then
    env_file="$2"
    shift 2
  fi

  append_command_text "$log_file" "$env_file" "$(shell_join "$@")"
}

shell_join() {
  printf '%q' "$1"
  shift
  local arg
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
}

require_file() {
  [[ -f "$1" ]] || die "file not found: $1"
}

require_dir() {
  [[ -d "$1" ]] || die "directory not found: $1"
}

tofu_bin() {
  if command -v tofu >/dev/null 2>&1; then
    echo tofu
  elif command -v terraform >/dev/null 2>&1; then
    echo terraform
  else
    die "neither tofu nor terraform found in PATH"
  fi
}

tofu_output_raw() {
  local tofu="$1"
  local tofu_dir="$2"
  local name="$3"
  "$tofu" -chdir="$tofu_dir" output -raw "$name"
}

ssh_base_args() {
  local key="$1"
  local known_hosts="${2:-}"
  printf '%s\n' -i "$key" -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR
  if [[ -n "$known_hosts" ]]; then
    printf '%s\n' -o UserKnownHostsFile="$known_hosts"
  fi
}

ssh_base_cmd() {
  local key="$1"
  local known_hosts="${2:-}"
  local -a args
  mapfile -t args < <(ssh_base_args "$key" "$known_hosts")
  shell_join ssh "${args[@]}"
}
