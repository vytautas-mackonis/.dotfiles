#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

if [[ "$OS_ENV" == wsl ]]; then
  printf 'Skipping VS Code installation in WSL (no graphical interface).\n'
  exit 0
fi

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      "$DOTFILES_DIR/scripts/homebrew/install.sh"
    fi
    brew install --cask visual-studio-code
    ;;
  linux:ubuntu)
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | sudo -n tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null
    printf '%s\n' \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | sudo -n tee /etc/apt/sources.list.d/vscode.list >/dev/null
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y code
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm code
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

command -v code >/dev/null
code --version
printf 'VS Code is installed.\n'
