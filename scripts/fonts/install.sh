#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/os-detect.sh"

case "$OS_FAMILY" in
  macos)
    FONT_DIR="$HOME/Library/Fonts"
    ;;
  linux)
    FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    ;;
  *)
    printf 'Unsupported operating system: %s\n' "$OS_NAME" >&2
    exit 1
    ;;
esac

mkdir -p "$FONT_DIR"
find "$DOTFILES_DIR/fonts" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp {} "$FONT_DIR/" \;

if [[ "$OS_FAMILY" == linux ]] && command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$FONT_DIR"
fi

printf 'Fonts installed for %s in %s\n' "$OS_NAME" "$FONT_DIR"
