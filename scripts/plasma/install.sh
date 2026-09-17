#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/os-detect.sh"

if [[ "$OS_FAMILY" != linux || "$OS_ENV" == wsl ]]; then
  printf 'Skipping Plasma settings on %s (%s).\n' "$OS_NAME" "$OS_ENV"
  exit 0
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
  KWRITECONFIG=kwriteconfig6
elif command -v kwriteconfig5 >/dev/null 2>&1; then
  KWRITECONFIG=kwriteconfig5
else
  printf 'Skipping Plasma settings: kwriteconfig was not found.\n'
  exit 0
fi

"$KWRITECONFIG" --file kcminputrc --group Keyboard --key NumLock 0
printf 'Plasma keyboard settings installed: NumLock enabled at session startup.\n'
