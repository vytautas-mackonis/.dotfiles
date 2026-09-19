#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

MARKER="# Added by dotfiles"
LEGACY_MARKER="# Added by ~/.dotfiles"

add_bourne_path() {
  local file=$1
  touch "$file"
  if grep -Fqx "$MARKER" "$file" || grep -Fqx "$LEGACY_MARKER" "$file"; then
    # Move an existing managed include to the end if the user added content after it.
    awk -v marker="$MARKER" -v legacy_marker="$LEGACY_MARKER" \
      '($0 == marker || $0 == legacy_marker) { getline; next } { print }' \
      "$file" > "$file.tmp"
    cat "$file.tmp" > "$file"
    rm -f "$file.tmp"
  fi
  {
    printf '\n%s\n' "$MARKER"
    printf '. "%s/shell/include.sh"\n' "$DOTFILES_DIR"
  } >> "$file"
}

# Cover interactive and login Bash, plus Zsh on macOS/Linux.
add_bourne_path "$HOME/.bashrc"
add_bourne_path "$HOME/.bash_profile"
add_bourne_path "$HOME/.zshrc"

FISH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
FISH_CONFIG="$FISH_CONFIG_DIR/config.fish"
mkdir -p "$FISH_CONFIG_DIR"
if [[ -f "$FISH_CONFIG" ]] && { grep -Fqx "$MARKER" "$FISH_CONFIG" || grep -Fqx "$LEGACY_MARKER" "$FISH_CONFIG"; }; then
  awk -v marker="$MARKER" -v legacy_marker="$LEGACY_MARKER" \
    '($0 == marker || $0 == legacy_marker) { getline; next } { print }' \
    "$FISH_CONFIG" > "$FISH_CONFIG.tmp"
  cat "$FISH_CONFIG.tmp" > "$FISH_CONFIG"
  rm -f "$FISH_CONFIG.tmp"
fi
{
  printf '\n%s\n' "$MARKER"
  printf 'source "%s/shell/include.fish"\n' "$DOTFILES_DIR"
} >> "$FISH_CONFIG"

INPUTRC="$HOME/.inputrc"
if [[ ! -f "$INPUTRC" ]]; then
  touch "$INPUTRC"
fi
if ! grep -Fqx 'set bell-style none' "$INPUTRC"; then
  printf '\nset bell-style none\n' >> "$INPUTRC"
fi

printf 'Added the dotfiles general include to Bash, Zsh, and Fish.\n'
