#!/usr/bin/env bash
set -euo pipefail

STORAGE_ENV=""
LOCAL_MOUNT_POINT=""
LOCAL_FILESYSTEM=""
BLOCK_MOUNT_POINT=""
BLOCK_FILESYSTEM=""

usage() {
  cat >&2 <<USAGE
usage: $0 --storage-env PATH [--local-mount-point PATH] [--local-filesystem ext4|xfs|raw] [--block-mount-point PATH] [--block-filesystem ext4|xfs|raw]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --storage-env) STORAGE_ENV="$2"; shift 2 ;;
    --local-mount-point) LOCAL_MOUNT_POINT="$2"; shift 2 ;;
    --local-filesystem) LOCAL_FILESYSTEM="$2"; shift 2 ;;
    --block-mount-point) BLOCK_MOUNT_POINT="$2"; shift 2 ;;
    --block-filesystem) BLOCK_FILESYSTEM="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$STORAGE_ENV" ]] || { usage; exit 1; }
[[ -f "$STORAGE_ENV" ]] || { echo "storage env not found: $STORAGE_ENV" >&2; exit 1; }

# shellcheck disable=SC1090
source "$STORAGE_ENV"

log() {
  echo "[storage-prepare][$(date --iso-8601=seconds)] $*"
}

disk_mountpoints() {
  local device="$1"
  lsblk -nr -o MOUNTPOINT "$device" 2>/dev/null | sed '/^$/d' || true
}

unmount_disk_mountpoints() {
  local device="$1"
  local mountpoint
  disk_mountpoints "$device" | sort -r | while read -r mountpoint; do
    [[ -n "$mountpoint" ]] || continue
    log "unmounting $mountpoint from $device"
    umount "$mountpoint"
  done
}

fstab_without_target() {
  local device="$1"
  local mount_point="$2"
  local uuid
  uuid="$(blkid -s UUID -o value "$device" 2>/dev/null || true)"

  awk -v device="$device" -v mount_point="$mount_point" -v uuid="$uuid" '
    BEGIN {
      keep_uuid = (uuid == "")
    }
    /^[[:space:]]*#/ || NF == 0 { print; next }
    $1 == device { next }
    $2 == mount_point { next }
    !keep_uuid && $1 == ("UUID=" uuid) { next }
    { print }
  ' /etc/fstab >/etc/fstab.cloud-measuring.tmp
  mv /etc/fstab.cloud-measuring.tmp /etc/fstab
}

ensure_mount_dir() {
  local mount_point="$1"
  mkdir -p "$mount_point"
  chown ubuntu:ubuntu "$mount_point"
}

format_device() {
  local device="$1"
  local fstype="$2"

  case "$fstype" in
    xfs) mkfs.xfs -f "$device" ;;
    ext4) mkfs.ext4 -F "$device" ;;
    *) echo "unsupported filesystem: $fstype" >&2; exit 1 ;;
  esac
}

prepare_raw() {
  local device="$1"
  local mount_point="$2"

  unmount_disk_mountpoints "$device"
  fstab_without_target "$device" "$mount_point"
  if [[ -n "$mount_point" ]]; then
    mkdir -p "$mount_point"
  fi
  log "wiping signatures on $device for raw target"
  wipefs -a "$device"
}

prepare_filesystem() {
  local device="$1"
  local mount_point="$2"
  local fstype="$3"
  local uuid

  [[ -n "$mount_point" ]] || { echo "mount point required for filesystem target" >&2; exit 1; }
  unmount_disk_mountpoints "$device"
  fstab_without_target "$device" "$mount_point"
  log "formatting $device as $fstype"
  format_device "$device" "$fstype"
  ensure_mount_dir "$mount_point"
  log "mounting $device at $mount_point"
  mount "$device" "$mount_point"
  chown ubuntu:ubuntu "$mount_point"

  uuid="$(blkid -s UUID -o value "$device")"
  echo "UUID=$uuid $mount_point $fstype defaults,nofail 0 2" >> /etc/fstab
}

rewrite_storage_env() {
  local path="$1"
  local tmp
  tmp="$(mktemp)"
  {
    echo "#!/usr/bin/env bash"
    echo "export STORAGE_TARGETS=$(printf '%q' "$STORAGE_TARGETS")"
    [[ -n "${STORAGE_ROOT_DEVICE:-}" ]] && echo "export STORAGE_ROOT_DEVICE=$(printf '%q' "$STORAGE_ROOT_DEVICE")"
    [[ -n "${STORAGE_LOCAL_DEVICE:-}" ]] && echo "export STORAGE_LOCAL_DEVICE=$(printf '%q' "$STORAGE_LOCAL_DEVICE")"
    if [[ -n "${STORAGE_LOCAL_DEVICE:-}" ]]; then
      if [[ "${STORAGE_LOCAL_FILESYSTEM:-}" == "raw" ]]; then
        echo "export STORAGE_LOCAL_FILESYSTEM=raw"
      else
        echo "export STORAGE_LOCAL_MOUNT=$(printf '%q' "$STORAGE_LOCAL_MOUNT")"
        echo "export STORAGE_LOCAL_FILESYSTEM=$(printf '%q' "$STORAGE_LOCAL_FILESYSTEM")"
      fi
    fi
    [[ -n "${STORAGE_BLOCK_DEVICE:-}" ]] && echo "export STORAGE_BLOCK_DEVICE=$(printf '%q' "$STORAGE_BLOCK_DEVICE")"
    if [[ -n "${STORAGE_BLOCK_DEVICE:-}" ]]; then
      if [[ "${STORAGE_BLOCK_FILESYSTEM:-}" == "raw" ]]; then
        echo "export STORAGE_BLOCK_FILESYSTEM=raw"
      else
        echo "export STORAGE_BLOCK_MOUNT=$(printf '%q' "$STORAGE_BLOCK_MOUNT")"
        echo "export STORAGE_BLOCK_FILESYSTEM=$(printf '%q' "$STORAGE_BLOCK_FILESYSTEM")"
      fi
    fi
  } >"$tmp"
  mv "$tmp" "$path"
  chown ubuntu:ubuntu "$path"
  chmod 0644 "$path"
}

configure_target() {
  local target_name="$1"
  local device_var="STORAGE_${target_name^^}_DEVICE"
  local mount_var="STORAGE_${target_name^^}_MOUNT"
  local filesystem_var="STORAGE_${target_name^^}_FILESYSTEM"
  local device="${!device_var:-}"
  local mount_point=""
  local filesystem=""

  [[ -n "$device" ]] || return 0
  case "$target_name" in
    local)
      mount_point="$LOCAL_MOUNT_POINT"
      filesystem="$LOCAL_FILESYSTEM"
      ;;
    block)
      mount_point="$BLOCK_MOUNT_POINT"
      filesystem="$BLOCK_FILESYSTEM"
      ;;
    *)
      echo "unknown target name: $target_name" >&2
      exit 1
      ;;
  esac
  [[ -n "$filesystem" ]] || { echo "filesystem value missing for target $target_name" >&2; exit 1; }

  case "$filesystem" in
    raw)
      prepare_raw "$device" "$mount_point"
      printf -v "$mount_var" '%s' ""
      printf -v "$filesystem_var" '%s' "$filesystem"
      ;;
    ext4|xfs)
      prepare_filesystem "$device" "$mount_point" "$filesystem"
      printf -v "$mount_var" '%s' "$mount_point"
      printf -v "$filesystem_var" '%s' "$filesystem"
      ;;
    *)
      echo "unsupported filesystem value for target $target_name: $filesystem" >&2
      exit 1
      ;;
  esac
}

for target_name in $STORAGE_TARGETS; do
  configure_target "$target_name"
done

rewrite_storage_env "$STORAGE_ENV"
