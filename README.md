# Dotfiles

A deliberately small, incremental dotfiles setup for macOS, Ubuntu (including Ubuntu on WSL), and Arch-based Linux distributions (including CachyOS).

## Current installation steps

The installer currently:

1. Detects the operating system and distribution.
2. Installs the bundled fonts for the current OS.
3. Installs tmux using Homebrew, apt, or pacman.
4. Installs the latest Vim version available from the platform package manager.
5. Configures Vim with the plugin set from the previous dotfiles repository using vim-plug.

Run from this directory:

```bash
./install.sh
```

The scripts make user-level font directories. On macOS, Homebrew is bootstrapped noninteractively if it is missing; on Linux, `sudo` is authenticated once for package installation. WSL is treated as Ubuntu for package installation; fonts are installed inside WSL and are not automatically installed on the Windows host. Shell configuration and other dotfiles will be added incrementally.
