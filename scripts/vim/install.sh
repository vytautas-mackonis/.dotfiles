#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Homebrew is required to install Vim on macOS.\n' >&2
      exit 1
    fi
    brew install vim
    ;;
  linux:ubuntu)
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y vim build-essential
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm vim gcc make
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

VIM_DIR="$HOME/.vim"
VIMRC="$VIM_DIR/vimrc"
mkdir -p "$VIM_DIR/autoload" "$VIM_DIR/swapfiles"

if [[ ! -f "$VIM_DIR/autoload/plug.vim" ]]; then
  curl -fLo "$VIM_DIR/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

VIMRC_SOURCE="$DOTFILES_DIR/vim/vimrc"
if [[ -e "$VIMRC" || -L "$VIMRC" ]]; then
  VIMRC_TARGET=$(readlink "$VIMRC" 2>/dev/null || true)
  if [[ "$VIMRC_TARGET" != "$VIMRC_SOURCE" ]]; then
    mv "$VIMRC" "$VIMRC.backup"
  fi
fi
ln -sfn "$VIMRC_SOURCE" "$VIMRC"

# The first pass may return non-zero because vimrc references plugins before they are installed.
# Run it anyway so PlugInstall can bootstrap the plugin tree; the second pass is strict.
vim -Nu "$VIMRC" -n -es \
  +'PlugInstall --sync' \
  +qall || true

vim -Nu "$VIMRC" -n -es \
  +'PlugInstall --sync' \
  +'silent! PlugClean!' \
  +qall </dev/null
printf 'Vim, its configuration, and its plugins are synced.\n'
