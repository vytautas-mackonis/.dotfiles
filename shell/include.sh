# General Bash/Zsh include for dotfiles.
# Settings here are sourced last so they override earlier shell settings.

if [ -n "${BASH_SOURCE[0]:-}" ]; then
    DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
elif [ -n "${ZSH_VERSION:-}" ]; then
    DOTFILES_DIR=$(cd -- "$(dirname -- "${(%):-%x}")/.." && pwd)
else
    DOTFILES_DIR="$HOME/.dotfiles"
fi

export DOTFILES_DIR
export BUN_INSTALL="$HOME/.bun"
export DENO_INSTALL="$HOME/.deno"
export PATH="/opt/homebrew/bin:/usr/local/bin:$DOTFILES_DIR/bin:$HOME/bin:$HOME/.local/bin:$HOME/.local/share/fnm:$BUN_INSTALL/bin:$DENO_INSTALL/bin:$PATH"

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi

if command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
    alias docker='podman'
fi

export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '\''{
if (length($0) > 20) { if (NF>4) print $1 "/" $2 "/.../" $(NF-1) "/" $NF;
else if (NF>3) print $1 "/" $2 "/.../" $NF;
else print $1 "/.../" $NF; }
else print $0;}'\'')'

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz vcs_info
    precmd_vcs_info () {
        vcs_info
    }
    precmd_functions+=( precmd_vcs_info )
    setopt prompt_subst
    zstyle ':vcs_info:git:*' formats '%F{240}(%b)%r%f'
    zstyle ':vcs_info:*' enable git
    export PROMPT='%F{cyan}%n%f@%F{green}%m%f:%F{yellow}$(eval "echo ${MYPS}")%f$ '
    export RPROMPT=\$vcs_info_msg_0_
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
else
    export PS1='\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]$(eval "echo ${MYPS}")\[\033[m\]\$ '
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
fi

# macOS Terminal appearance and platform-specific ls behavior.
if [ "$(uname)" = "Darwin" ]; then
    osascript -e "tell application \"Terminal\" to set background color of window 1 to {5632, 5632, 5632}"
    osascript -e "tell application \"Terminal\" to set the font name of window 1 to \"Consolas\""
    alias ls='ls -G'
else
    alias ls='ls -GFh --color=auto'
fi

