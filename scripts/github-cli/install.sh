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
    brew install --yes gh
    ;;
  linux:ubuntu)
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y gh
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm github-cli
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

command -v gh >/dev/null
gh --version
printf 'GitHub CLI is installed.\n'
