#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/os-detect.sh"

printf 'Detected: %s (family=%s, distro=%s, environment=%s)\n' "$OS_NAME" "$OS_FAMILY" "$OS_DISTRO" "$OS_ENV"

# Authenticate once where package installation may need administrator access.
if [[ "$OS_FAMILY" == linux || "$OS_FAMILY" == macos ]]; then
  sudo -v
fi

if [[ "$OS_FAMILY" == macos ]] && ! command -v brew >/dev/null 2>&1; then
  printf 'Installing Homebrew noninteractively...\n'
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Make Homebrew available in this invocation on both Intel and Apple Silicon.
  for brew_prefix in /opt/homebrew /usr/local; do
    if [[ -x "$brew_prefix/bin/brew" ]]; then
      export PATH="$brew_prefix/bin:$PATH"
      break
    fi
  done
fi

"$DOTFILES_DIR/scripts/fonts/install.sh"
"$DOTFILES_DIR/scripts/tmux/install.sh"
"$DOTFILES_DIR/scripts/vim/install.sh"
