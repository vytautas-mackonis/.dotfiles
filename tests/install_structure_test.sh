#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$ROOT/$1" ]] || fail "missing $1"
}

assert_executable() {
  [[ -x "$ROOT/$1" ]] || fail "$1 is not executable"
}

assert_contains() {
  local file=$1
  local expected=$2
  grep -Fq -- "$expected" "$ROOT/$file" || fail "$file does not contain: $expected"
}

for tool in homebrew python node bun deno fzf podman; do
  script="scripts/$tool/install.sh"
  assert_file "$script"
  assert_executable "$script"
  assert_contains "$script" 'source "$SCRIPT_DIR/../common.sh"'
  assert_contains "install.sh" '"$DOTFILES_DIR/'"$script"'"'
done

assert_contains shell/include.sh 'eval "$(fnm env --use-on-cd)"'
assert_contains shell/include.sh 'BUN_INSTALL="$HOME/.bun"'
assert_contains shell/include.sh 'DENO_INSTALL="$HOME/.deno"'
assert_contains shell/include.sh "if command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then"
assert_contains shell/include.sh "alias docker='podman'"
assert_contains shell/include.fish 'fnm env --use-on-cd | source'
assert_contains shell/include.fish 'set -gx BUN_INSTALL "$HOME/.bun"'
assert_contains shell/include.fish 'set -gx DENO_INSTALL "$HOME/.deno"'
assert_contains shell/include.fish 'if command -q podman; and not command -q docker'
assert_contains shell/include.fish "alias docker 'podman'"

assert_contains scripts/python/install.sh 'command -v python'
assert_contains scripts/python/install.sh 'command -v python3'
assert_contains scripts/node/install.sh 'command -v node'
assert_contains scripts/node/install.sh 'command -v npm'
assert_contains scripts/bun/install.sh 'command -v bun'
assert_contains scripts/deno/install.sh 'command -v deno'
assert_contains scripts/fzf/install.sh 'command -v fzf'
assert_contains scripts/podman/install.sh 'command -v podman'
assert_executable tests/verify-install.sh
assert_contains tests/verify-install.sh 'for command in python python3 node npm bun deno fzf podman tmux vim; do'
assert_contains tests/verify-install.sh 'command -v "$command"'
assert_contains tests/verify-install.sh 'readlink "$HOME/.vim/vimrc"'
assert_contains tests/verify-install.sh 'readlink "$HOME/.tmux.conf"'
assert_contains scripts/homebrew/install.sh 'command -v brew'
assert_contains scripts/homebrew/install.sh 'brew --version'
assert_contains scripts/shell/install.sh "sed -i.bak '/^set bell-style /d'"
assert_contains scripts/tmux/install.sh 'command -v tmux'
assert_contains scripts/tmux/install.sh 'tmux -V'
assert_contains scripts/tmux/install.sh 'source-file -n'
assert_contains scripts/tmux/install.sh 'ln -sfn'
assert_contains scripts/tmux/install.sh 'git clone https://github.com/tmux-plugins/tpm'
assert_contains scripts/tmux/install.sh 'install_plugins'
assert_contains scripts/tmux/install.sh 'update_plugins" all'
assert_contains scripts/vim/install.sh 'PlugInstall --sync'
assert_contains scripts/vim/install.sh 'PlugUpdate --sync'
assert_contains scripts/vim/install.sh 'PlugClean!'
assert_contains scripts/vim/install.sh 'ln -sfn'

if grep -Fq 'python python3 node npm bun deno fzf podman' "$ROOT/Vagrantfile"; then
  fail 'Vagrantfile should rely on installers for command verification'
fi
assert_contains Vagrantfile '/run/systemd/resolve/stub-resolv.conf'
assert_contains Vagrantfile '"windows-wsl"'
assert_contains Vagrantfile 'gusztavvargadr/windows-10'
assert_contains Vagrantfile 'Microsoft-Windows-Subsystem-Linux'
assert_contains Vagrantfile 'VirtualMachinePlatform'
assert_contains Vagrantfile 'wsl.exe -l -v'
assert_contains Vagrantfile 'wsl.exe -d Ubuntu'

printf 'install structure test passed\n'
