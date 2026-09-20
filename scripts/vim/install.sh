#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

vim_is_compatible() {
  vim --version >/dev/null 2>&1 && vim -Nu NONE -n -es \
    +'if !has("patch-9.1.1646") | cquit | endif' \
    +qall </dev/null
}

build_latest_vim() {
  local build_dir
  build_dir=$(mktemp -d)
  git clone --depth 1 https://github.com/vim/vim.git "$build_dir/vim"
  (
    cd "$build_dir/vim"
    ./configure --prefix=/usr/local --with-features=huge \
      --enable-multibyte --enable-terminal --disable-gui
    make -j"$(nproc)"
    sudo -n make install
  )
  rm -rf "$build_dir"
}

case "$OS_FAMILY:$OS_DISTRO" in
  macos:*)
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Homebrew is required to install Vim on macOS.\n' >&2
      exit 1
    fi
    brew install --yes vim
    ;;
  linux:ubuntu)
    # The PPA supports older Ubuntu releases, while newer releases need the
    # latest Vim source because their repositories may not have 9.1.1646 yet.
    DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y software-properties-common
    ubuntu_codename=${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}
    case "$ubuntu_codename" in
      focal|jammy)
        sudo -n add-apt-repository -y ppa:jonathonf/vim
        DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
        DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y vim build-essential
        ;;
      *)
        sudo -n add-apt-repository --remove -y ppa:jonathonf/vim >/dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y vim build-essential git libncurses-dev
        ;;
    esac
    ;;
  linux:arch)
    sudo -n pacman -S --needed --noconfirm vim gcc make
    ;;
  *)
    printf 'Unsupported operating system/distribution: %s (%s)\n' "$OS_NAME" "$OS_DISTRO" >&2
    exit 1
    ;;
esac

if ! vim_is_compatible; then
  if [[ "$OS_FAMILY:$OS_DISTRO" == linux:ubuntu ]]; then
    build_latest_vim
  fi
fi
if ! vim_is_compatible; then
  printf 'Vim 9.1.1646 or newer is required by denops.vim and ddc.vim.\n' >&2
  exit 1
fi

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
