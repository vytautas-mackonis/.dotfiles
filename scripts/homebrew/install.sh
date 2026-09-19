#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

if [[ "$OS_FAMILY" != macos ]]; then
  printf 'Homebrew is only installed on macOS; skipping.\n'
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'Installing Homebrew noninteractively...\n'
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make Homebrew available in this invocation on both Intel and Apple Silicon.
for brew_prefix in /opt/homebrew /usr/local; do
  if [[ -x "$brew_prefix/bin/brew" ]]; then
    export PATH="$brew_prefix/bin:$PATH"
    break
  fi
done

printf 'Homebrew is installed.\n'
