#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

install_prerequisites() {
  case "$OS_FAMILY:$OS_DISTRO" in
    macos:*)
      ;;
    linux:ubuntu)
      sudo apt-get update
      DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ca-certificates curl unzip
      ;;
    linux:arch)
      sudo pacman -S --needed --noconfirm ca-certificates curl unzip
      ;;
    *)
      printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
      exit 1
      ;;
  esac
}

install_prerequisites
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

command -v bun >/dev/null
bun --version
printf 'Bun is installed.\n'
