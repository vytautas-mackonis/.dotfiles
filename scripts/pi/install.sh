#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/common.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/pi/skills.conf"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Pi installer requires %s.\n' "$1" >&2
    exit 1
  }
}

require_command npm
require_command git
require_command node

npm install --global --ignore-scripts @earendil-works/pi-coding-agent
require_command pi
PI_BIN=$(command -v pi)

PI_AGENT_DIR="$HOME/.pi/agent"
SETTINGS_PATH="$PI_AGENT_DIR/settings.json"
mkdir -p "$PI_AGENT_DIR"

if [[ -L "$SETTINGS_PATH" && "$(readlink "$SETTINGS_PATH")" == "$DOTFILES_DIR/pi/settings.json" ]]; then
  :
elif [[ -e "$SETTINGS_PATH" || -L "$SETTINGS_PATH" ]]; then
  backup="$SETTINGS_PATH.bak.$(date +%Y%m%d%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup+=".1"
  done
  mv -- "$SETTINGS_PATH" "$backup"
fi
ln -sfn -- "$DOTFILES_DIR/pi/settings.json" "$SETTINGS_PATH"

package_list=$(mktemp)
cleanup() {
  rm -f -- "$package_list"
}
trap cleanup EXIT
if ! node -e '
const fs = require("fs");
const settings = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
if (!Array.isArray(settings.packages) || settings.packages.some((pkg) => typeof pkg !== "string")) process.exit(2);
process.stdout.write(settings.packages.join("\n") + "\n");
' "$DOTFILES_DIR/pi/settings.json" >"$package_list"; then
  printf 'Pi settings packages must be an array of strings.\n' >&2
  exit 1
fi
while IFS= read -r package; do
  [[ -n "$package" ]] || continue
  "$PI_BIN" install "$package"
done <"$package_list"

clone_or_update() {
  local repo=$1
  local directory=$2
  if [[ -e "$directory" || -L "$directory" ]]; then
    [[ -d "$directory" ]] || {
      printf 'Skill checkout path is not a directory: %s\n' "$directory" >&2
      exit 1
    }
    git -C "$directory" pull --ff-only
  else
    mkdir -p "$(dirname -- "$directory")"
    git clone "$repo" "$directory"
  fi
}

clone_or_update "$MATTPOCOCK_SKILLS_REPO" "$MATTPOCOCK_SKILLS_DIR"
clone_or_update "$SUPERPOWERS_SKILLS_REPO" "$SUPERPOWERS_SKILLS_DIR"
