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
      DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ca-certificates curl
      ;;
    linux:arch)
      sudo pacman -S --needed --noconfirm ca-certificates curl
      ;;
    *)
      printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
      exit 1
      ;;
  esac
}

install_prerequisites

UV_BIN="$HOME/.local/bin/uv"
if [[ ! -x "$UV_BIN" ]]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

"$UV_BIN" self update || true
"$UV_BIN" python install
PYTHON_BIN=$("$UV_BIN" python find --managed-python)
mkdir -p "$HOME/.local/bin"
ln -sf "$PYTHON_BIN" "$HOME/.local/bin/python"
ln -sf "$PYTHON_BIN" "$HOME/.local/bin/python3"
export PATH="$HOME/.local/bin:$PATH"

command -v python >/dev/null
command -v python3 >/dev/null
python --version
python3 --version
printf 'Latest uv-managed Python is installed at %s.\n' "$PYTHON_BIN"
