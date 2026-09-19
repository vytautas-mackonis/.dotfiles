#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR=${DOTFILES_DIR:?DOTFILES_DIR must be set}

for command in python python3 node npm bun deno fzf podman tmux vim; do
  command -v "$command" >/dev/null
done

test "$(readlink "$HOME/.vim/vimrc")" = "$DOTFILES_DIR/vim/vimrc"
test "$(readlink "$HOME/.tmux.conf")" = "$DOTFILES_DIR/tmux/tmux.conf"
test -d "$HOME/.tmux/plugins/tpm/.git"
test -d "$HOME/.tmux/plugins/tmux-yank/.git"
test "$(tail -n 1 "$HOME/.inputrc")" = 'set bell-style none'
test "$(grep -c '^set bell-style ' "$HOME/.inputrc")" -eq 1

printf 'Desired-state verification passed.\n'
