#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Rust installer requires %s.\n' "$1" >&2
    exit 1
  }
}

CARGO_HOME_DIR="${CARGO_HOME:-$HOME/.cargo}"
if command -v rustup >/dev/null 2>&1; then
  RUSTUP_BIN=$(command -v rustup)
else
  require_command curl
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  RUSTUP_BIN="$CARGO_HOME_DIR/bin/rustup"
  [[ -x "$RUSTUP_BIN" ]] || {
    printf 'Rustup was not installed at %s.\n' "$RUSTUP_BIN" >&2
    exit 1
  }
fi

"$RUSTUP_BIN" toolchain install stable --profile default
"$RUSTUP_BIN" default stable

CARGO_BIN="$CARGO_HOME_DIR/bin"
if [[ -x "$CARGO_BIN/cargo" ]]; then
  "$CARGO_BIN/cargo" --version
else
  require_command cargo
  cargo --version
fi
if [[ -x "$CARGO_BIN/rustc" ]]; then
  "$CARGO_BIN/rustc" --version
else
  require_command rustc
  rustc --version
fi
printf 'Rust stable is installed with rustup.\n'
