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

for path in scripts/pi/install.sh bin/pi-superpowers bin/pi-update pi/settings.json pi/skills.conf; do
  assert_file "$path"
done
for path in scripts/pi/install.sh bin/pi-superpowers bin/pi-update; do
  assert_executable "$path"
done
assert_contains install.sh '"$DOTFILES_DIR/scripts/pi/install.sh"'
assert_contains install.sh 'ps -p "$PPID" -o comm='
assert_contains install.sh 'Reload the current shell'
assert_contains install.sh 'env --shell bash'
if grep -Fq 'readlink -f' "$ROOT/scripts/pi/install.sh"; then
  fail 'Pi installer must use portable symlink comparison'
fi
assert_contains pi/settings.json '"defaultProvider": "openai-codex"'
assert_contains pi/settings.json '"defaultModel": "gpt-5.6-luna"'
assert_contains pi/settings.json '"defaultThinkingLevel": "medium"'
assert_contains pi/settings.json 'npm:pi-subagents'
assert_contains pi/settings.json 'npm:@gotgenes/pi-anthropic-auth'
assert_contains tests/pi_install_test.sh 'cmp "$HOME/.pi/agent/auth.json"'
assert_contains tests/pi_install_test.sh 'cmp "$HOME/.pi/agent/models-store.json"'
assert_contains tests/pi_install_test.sh 'lastChangelogVersion'
if grep -Eqi 'mattpocock|superpowers' "$ROOT/pi/settings.json"; then
  fail 'pi/settings.json should not select a skillset'
fi
assert_contains README.md '## Pi Coding Agent'

assert_file scripts/rust/install.sh
assert_executable scripts/rust/install.sh
assert_contains scripts/rust/install.sh 'source "$SCRIPT_DIR/../common.sh"'
assert_contains scripts/rust/install.sh 'toolchain install stable --profile default'
assert_contains scripts/rust/install.sh 'default stable'
assert_contains install.sh '"$DOTFILES_DIR/scripts/rust/install.sh"'

for tool in homebrew python node bun deno fzf podman github-cli gitlab-cli; do
  script="scripts/$tool/install.sh"
  assert_file "$script"
  assert_executable "$script"
  assert_contains "$script" 'source "$SCRIPT_DIR/../common.sh"'
  assert_contains "install.sh" '"$DOTFILES_DIR/'"$script"'"'
done

assert_contains shell/include.sh 'eval "$(fnm env --use-on-cd)"'
assert_contains shell/include.sh 'pi() {'
assert_contains shell/include.sh 'command pi --skill "$HOME/agent-skillsets/mattpocock-skills/skills" "$@"'
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
assert_contains scripts/podman/install.sh 'Delegate=yes'
assert_contains scripts/podman/install.sh 'user@.service.d'
assert_contains scripts/podman/install.sh 'sudo -n systemctl set-property --runtime "user@${uid}.service" Delegate=yes'
if grep -Fq 'systemctl --user set-property --runtime user.slice Delegate=yes' "$ROOT/scripts/podman/install.sh"; then
  fail 'Podman installer must not set Delegate on user.slice'
fi
assert_contains scripts/github-cli/install.sh 'brew install --yes gh'
assert_contains scripts/github-cli/install.sh 'sudo -n apt-get install -y gh'
assert_contains scripts/github-cli/install.sh 'sudo -n pacman -S --needed --noconfirm github-cli'
assert_contains scripts/github-cli/install.sh 'command -v gh'
assert_contains scripts/gitlab-cli/install.sh 'brew install --yes glab'
assert_contains scripts/gitlab-cli/install.sh 'sudo -n apt-get install -y glab'
assert_contains scripts/gitlab-cli/install.sh 'sudo -n pacman -S --needed --noconfirm glab'
assert_contains scripts/gitlab-cli/install.sh 'command -v glab'
assert_contains scripts/homebrew/install.sh 'command -v brew'
assert_contains scripts/homebrew/install.sh 'brew --version'
assert_contains scripts/shell/install.sh "sed -i.bak '/^set bell-style /d'"
assert_contains scripts/tmux/install.sh 'command -v tmux'
assert_contains scripts/tmux/install.sh 'tmux -V'
assert_contains scripts/tmux/install.sh 'wl-clipboard xclip'
assert_contains scripts/tmux/install.sh 'sudo -n pacman -S --needed --noconfirm tmux wl-clipboard xclip'
assert_contains tmux/tmux.conf '@override_copy_command'
assert_contains tmux/tmux.conf 'xclip -selection clipboard'
assert_contains scripts/tmux/install.sh 'source-file -n'
assert_contains scripts/tmux/install.sh 'ln -sfn'
assert_contains scripts/tmux/install.sh 'git clone https://github.com/tmux-plugins/tpm'
assert_contains scripts/tmux/install.sh 'install_plugins'
assert_contains scripts/tmux/install.sh 'update_plugins" all'
assert_contains scripts/vim/install.sh 'PlugInstall --sync'
assert_contains scripts/vim/install.sh 'vim -Nu "$VIMRC" -n'
assert_contains scripts/vim/install.sh 'PlugClean!'
assert_contains scripts/vim/install.sh 'ln -sfn'
assert_contains scripts/vim/install.sh 'ppa:jonathonf/vim'
assert_contains scripts/vim/install.sh 'git clone --depth 1 https://github.com/vim/vim.git'
assert_contains scripts/vim/install.sh 'make install'
assert_contains scripts/vim/install.sh 'vim --version'
assert_contains scripts/vim/install.sh '9.1.1646'
assert_contains bin/pi-superpowers '--skill "$HOME/agent-skillsets/superpowers/skills"'
assert_contains bin/pi-superpowers '.pi/extensions/superpowers.ts'
assert_contains shell/include.fish 'agent-skillsets/mattpocock-skills/skills'
assert_contains pi/skills.conf 'agent-skillsets/mattpocock-skills'
assert_contains pi/skills.conf 'agent-skillsets/superpowers'
if grep -Fq -- '--no-skills' "$ROOT/bin/pi-superpowers"; then
  fail 'pi-superpowers should preserve normal skill discovery'
fi
if grep -Fqi -- 'mattpocock' "$ROOT/bin/pi-superpowers"; then
  fail 'pi-superpowers should not load Matt Pocock skills'
fi
assert_contains bin/pi-update 'update --all'

if grep -Fq 'python python3 node npm bun deno fzf podman' "$ROOT/Vagrantfile"; then
  fail 'Vagrantfile should rely on installers for command verification'
fi
assert_contains Vagrantfile '/run/systemd/resolve/stub-resolv.conf'
assert_contains Vagrantfile '"windows-wsl"'
assert_contains Vagrantfile 'gusztavvargadr/windows-11'
assert_contains Vagrantfile 'Microsoft-Windows-Subsystem-Linux'
assert_contains Vagrantfile 'VirtualMachinePlatform'
assert_contains Vagrantfile 'wsl.exe -l -v'
assert_contains Vagrantfile 'wsl.exe -d Ubuntu'
assert_contains Vagrantfile 'DOTFILES_TEST_ARCHIVE'
assert_contains Vagrantfile 'tar -xzf'
assert_contains Vagrantfile '"macos"'
assert_contains Vagrantfile 'ghcr.io/cirruslabs/macos-sequoia-base:latest'
assert_contains Vagrantfile 'tart.volumes'
assert_contains Vagrantfile 'mount_virtiofs'
assert_contains README.md 'vagrant up windows-wsl'
assert_contains README.md 'vagrant up macos --provider=tart'

printf 'install structure test passed\n'
