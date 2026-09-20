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

if command -v fnm >/dev/null 2>&1; then
  FNM_BIN=$(command -v fnm)
else
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  FNM_BIN=$(command -v fnm 2>/dev/null || printf '%s' "$HOME/.local/share/fnm/fnm")
fi

if [[ ! -x "$FNM_BIN" ]]; then
  printf 'Unable to locate fnm after installation.\n' >&2
  exit 1
fi

LATEST_NODE_VERSION=$("$FNM_BIN" ls-remote | awk '/^v[0-9]+\.[0-9]+\.[0-9]+/ { print $1 }' | tail -n 1)
if [[ -z "$LATEST_NODE_VERSION" ]]; then
  printf 'Unable to determine latest Node.js version.\n' >&2
  exit 1
fi

"$FNM_BIN" install "$LATEST_NODE_VERSION"
"$FNM_BIN" default "$LATEST_NODE_VERSION"
# shellcheck disable=SC1090
source <("$FNM_BIN" env --shell bash)

command -v node >/dev/null
command -v npm >/dev/null
node --version
npm --version
printf 'Latest Node.js %s is installed with fnm.\n' "$LATEST_NODE_VERSION"
