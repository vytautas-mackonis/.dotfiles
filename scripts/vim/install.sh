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
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y vim make
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm vim make
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

if [[ -e "$VIMRC" || -L "$VIMRC" ]]; then
  if [[ "$(readlink -f "$VIMRC" 2>/dev/null || true)" != "$DOTFILES_DIR/vim/vimrc" ]]; then
    mv "$VIMRC" "$VIMRC.backup"
  fi
fi
if [[ ! -e "$VIMRC" && ! -L "$VIMRC" ]]; then
  ln -s "$DOTFILES_DIR/vim/vimrc" "$VIMRC"
fi

vim -Nu "$VIMRC" -n +PlugInstall +qall
printf 'Vim and its plugins are installed.\n'
