#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common.sh"

MARKER="# Added by dotfiles"

add_bourne_path() {
  local file=$1
  if [[ -L "$file" && ! -e "$file" ]]; then
    local backup="$file.backup"
    if [[ -e "$backup" || -L "$backup" ]]; then
      backup="$file.backup.$(date +%s)"
    fi
    mv "$file" "$backup"
  fi
  touch "$file"
  if grep -Fqx "$MARKER" "$file"; then
    # Move an existing managed include to the end if the user added content after it.
    awk -v marker="$MARKER" '($0 == marker) { getline; next } { print }' \
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
if [[ -f "$FISH_CONFIG" ]] && grep -Fqx "$MARKER" "$FISH_CONFIG"; then
  awk -v marker="$MARKER" '($0 == marker) { getline; next } { print }' \
    "$FISH_CONFIG" > "$FISH_CONFIG.tmp"
  cat "$FISH_CONFIG.tmp" > "$FISH_CONFIG"
  rm -f "$FISH_CONFIG.tmp"
fi
{
  printf '\n%s\n' "$MARKER"
  printf 'source "%s/shell/include.fish"\n' "$DOTFILES_DIR"
} >> "$FISH_CONFIG"

INPUTRC="$HOME/.inputrc"
touch "$INPUTRC"
sed -i.bak '/^set bell-style /d' "$INPUTRC"
rm -f "$INPUTRC.bak"
printf '\nset bell-style none\n' >> "$INPUTRC"

printf 'Added the dotfiles general include to Bash, Zsh, and Fish.\n'
