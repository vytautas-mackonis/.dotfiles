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

command -v podman >/dev/null
podman --version
printf 'Podman is installed.\n'
