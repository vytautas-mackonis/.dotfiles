# Dotfiles

A deliberately small, incremental dotfiles setup for macOS, Ubuntu (including Ubuntu on WSL), and Arch-based Linux distributions (including CachyOS).

## Current installation steps

The installer currently:

1. Detects the operating system and distribution.
2. Installs the bundled fonts for the current OS.
3. Configures KDE Plasma to enable NumLock at session startup when running on Linux with Plasma tools available.
4. Installs tmux using Homebrew, apt, or pacman, links the preserved tmux configuration, and installs its terminal definitions.
5. Installs the latest Vim version available from the platform package manager.
6. Configures Vim with the plugin set from the previous dotfiles repository using vim-plug.
7. Adds a general shell include to Bash, Zsh, and Fish configuration; it currently provides the shared PATH, prompt, aliases, colors, and macOS Terminal settings from the previous Bash configuration.

Run from this directory:

```bash
./install.sh
```

The scripts make user-level font directories. The general shell include is appended at the end of Bash, Zsh, and Fish startup files so its settings override earlier ones. On macOS, Homebrew is bootstrapped noninteractively if it is missing; on Linux, `sudo` is authenticated once for package installation. WSL is treated as Ubuntu for package installation; fonts are installed inside WSL and are not automatically installed on the Windows host. Shell configuration and other dotfiles will be added incrementally.
