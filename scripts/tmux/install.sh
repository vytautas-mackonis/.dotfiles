#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Homebrew is required to install tmux on macOS.\n' >&2
      exit 1
    fi
    brew install --yes tmux
    ;;
  linux:ubuntu)
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y tmux wl-clipboard xclip
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm tmux wl-clipboard xclip
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
ln -sfn "$TMUX_SOURCE" "$TMUX_CONF"

# Install the terminal definitions used by the preserved tmux configuration.
if command -v tic >/dev/null 2>&1; then
  tic -x "$DOTFILES_DIR/resources/tmux-256color-italic.terminfo"
  tic "$DOTFILES_DIR/resources/xterm-256color-italic.terminfo"
fi

validate_tmux_config() {
  local socket_name=dotfiles-install

  tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
  if tmux -L "$socket_name" -f /dev/null start-server \; source-file -n /dev/null \; kill-server >/dev/null 2>&1; then
    tmux -L "$socket_name" -f /dev/null start-server \; source-file -n "$TMUX_CONF" \; kill-server
  else
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
    tmux -L "$socket_name" -f "$TMUX_CONF" start-server \; kill-server
  fi
}

sync_tmux_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ ! -d "$tpm_dir/.git" ]]; then
    rm -rf "$tpm_dir"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  else
    git -C "$tpm_dir" pull --ff-only
  fi

  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$tpm_dir/bin/install_plugins"
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$tpm_dir/bin/update_plugins" all
}

command -v tmux >/dev/null
tmux -V
validate_tmux_config
sync_tmux_plugins

printf 'tmux and its configuration are installed.\n'
