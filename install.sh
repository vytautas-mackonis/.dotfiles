#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$DOTFILES_DIR/scripts/common.sh"

printf 'Detected: %s (family=%s, distro=%s, environment=%s)\n' "$OS_NAME" "$OS_FAMILY" "$OS_DISTRO" "$OS_ENV"

# Authenticate once where package installation may need administrator access.
if [[ "$OS_FAMILY" == linux || "$OS_FAMILY" == macos ]]; then
  if [[ -t 0 && -t 1 ]]; then
    sudo -v
  else
    sudo -n true
  fi
fi

export PATH="$DOTFILES_DIR/bin:$PATH"
"$DOTFILES_DIR/scripts/shell/install.sh"
"$DOTFILES_DIR/scripts/homebrew/install.sh"
if [[ "$OS_FAMILY" == macos ]]; then
  for brew_prefix in /opt/homebrew /usr/local; do
    if [[ -x "$brew_prefix/bin/brew" ]]; then
      export PATH="$brew_prefix/bin:$PATH"
      break
    fi
  done
fi
"$DOTFILES_DIR/scripts/python/install.sh"
"$DOTFILES_DIR/scripts/node/install.sh"
"$DOTFILES_DIR/scripts/rust/install.sh"
if [[ -x "$HOME/.local/share/fnm/fnm" ]]; then
  eval "$("$HOME/.local/share/fnm/fnm" env --shell bash)"
fi
"$DOTFILES_DIR/scripts/pi/install.sh"
"$DOTFILES_DIR/scripts/bun/install.sh"
"$DOTFILES_DIR/scripts/deno/install.sh"
if [[ -f "$HOME/.deno/env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.deno/env"
fi
"$DOTFILES_DIR/scripts/fzf/install.sh"
"$DOTFILES_DIR/scripts/podman/install.sh"
"$DOTFILES_DIR/scripts/github-cli/install.sh"
"$DOTFILES_DIR/scripts/gitlab-cli/install.sh"
"$DOTFILES_DIR/scripts/fonts/install.sh"
"$DOTFILES_DIR/scripts/plasma/install.sh"
"$DOTFILES_DIR/scripts/tmux/install.sh"
"$DOTFILES_DIR/scripts/vim/install.sh"

parent_shell=$(ps -p "$PPID" -o comm= 2>/dev/null | sed 's/^-//' | sed 's!.*/!!')
printf '\nReload the current shell with:\n'
case "$parent_shell" in
  fish)
    printf '  source "%s/fish/config.fish"\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
    ;;
  bash)
    printf '  source "%s/.bashrc"\n' "$HOME"
    ;;
  zsh)
    printf '  source "%s/.zshrc"\n' "$HOME"
    ;;
  *)
    printf '  restart your shell, or source its startup file manually\n'
    ;;
esac
