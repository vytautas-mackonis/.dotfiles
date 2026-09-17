#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/os-detect.sh"

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Homebrew is required to install tmux on macOS.\n' >&2
      exit 1
    fi
    brew install tmux
    ;;
  linux:ubuntu)
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y tmux
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm tmux
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

TMUX_CONF="$HOME/.tmux.conf"
TMUX_SOURCE="$DOTFILES_DIR/tmux/tmux.conf"
if [[ -e "$TMUX_CONF" || -L "$TMUX_CONF" ]]; then
  if [[ "$(readlink -f "$TMUX_CONF" 2>/dev/null || true)" != "$TMUX_SOURCE" ]]; then
    mv "$TMUX_CONF" "$TMUX_CONF.backup"
  fi
fi
if [[ ! -e "$TMUX_CONF" && ! -L "$TMUX_CONF" ]]; then
  ln -s "$TMUX_SOURCE" "$TMUX_CONF"
fi

# Install the terminal definitions used by the preserved tmux configuration.
if command -v tic >/dev/null 2>&1; then
  tic -x "$DOTFILES_DIR/resources/tmux-256color-italic.terminfo"
  tic "$DOTFILES_DIR/resources/xterm-256color-italic.terminfo"
fi

printf 'tmux and its configuration are installed.\n'
