# General Fish include for ~/.dotfiles.
# Settings here are loaded last so they override earlier shell settings.

set -gx CLICOLOR 1
set -gx LSCOLORS GxFxCxDxBxegedabagaced
fish_add_path --prepend /usr/local/bin "$HOME/.dotfiles/bin" "$HOME/bin" "$HOME/.local/bin"

# Keep the old prompt's user@host:path shape.
function fish_prompt
    set_color cyan
    printf '%s' (whoami)
    set_color normal
    printf '@'
    set_color green
    printf '%s' (hostname -s)
    set_color normal
    printf ':'
    set_color yellow
    printf '%s' (string replace --regex "^$HOME" '~' (pwd))
    set_color normal
    printf '$ '
end

# macOS Terminal appearance and platform-specific ls behavior.
if test (uname) = Darwin
    osascript -e 'tell application "Terminal" to set background color of window 1 to {5632, 5632, 5632}'
    osascript -e 'tell application "Terminal" to set the font name of window 1 to "Consolas"'
    alias ls 'ls -G'
else
    alias ls 'ls -GFh --color=auto'
end
