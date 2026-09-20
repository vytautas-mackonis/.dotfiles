#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      "$DOTFILES_DIR/scripts/homebrew/install.sh"
    fi
    brew install --yes podman
    ;;
  linux:ubuntu)
    sudo apt-get update
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y podman
    ;;
  linux:arch)
    sudo pacman -S --needed --noconfirm podman
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

configure_rootless_delegation() {
  if [[ "$OS_FAMILY" != linux ]]; then
    return
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    printf 'systemd is unavailable; skipping Podman rootless delegation.\n' >&2
    return
  fi

  local systemd_state
  systemd_state=$(sudo -n systemctl is-system-running 2>/dev/null || true)
  case "$systemd_state" in
    running|degraded)
      ;;
    *)
      printf 'systemd is not running; enable systemd to use rootless kind with Podman.\n' >&2
      return
      ;;
  esac

  local dropin_dir=/etc/systemd/system/user@.service.d
  local dropin_path="$dropin_dir/delegate.conf"
  sudo -n install -d -m 0755 "$dropin_dir"
  printf '[Service]\nDelegate=yes\n' | sudo -n tee "$dropin_path" >/dev/null
  sudo -n systemctl daemon-reload

  local uid
  uid=$(id -u)
  if ! sudo -n systemctl set-property --runtime "user@${uid}.service" Delegate=yes; then
    printf 'Could not apply Podman delegation to the current user session; log in again to activate it.\n' >&2
  fi
}

configure_rootless_delegation
command -v podman >/dev/null
podman --version
printf 'Podman is installed.\n'
