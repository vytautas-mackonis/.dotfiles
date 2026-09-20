# Dotfiles

A deliberately small, incremental dotfiles setup for macOS, Ubuntu (including Ubuntu on WSL), and Arch-based Linux distributions (including CachyOS).

## Current installation steps

The installer currently:

1. Detects the operating system and distribution.
2. Adds a general shell include to Bash, Zsh, and Fish configuration; it provides the shared PATH, prompt, aliases, colors, developer tool initialization, and macOS Terminal settings from the previous Bash configuration.
3. Installs Homebrew on macOS when it is missing.
4. Installs the latest Python available through uv and exposes it as `python` and `python3` from `~/.local/bin`.
5. Installs the latest Node.js through fnm and initializes fnm from the shell includes.
6. Installs the Rust stable toolchain through rustup.
7. Installs Bun, Deno, fzf, and Podman.
7. Installs the bundled fonts for the current OS.
8. Configures KDE Plasma to enable NumLock at session startup when running on Linux with Plasma tools available.
9. Installs tmux using Homebrew, apt, or pacman, links the preserved tmux configuration, and installs its terminal definitions.
10. Installs the latest Vim version available from the platform package manager.
11. Configures Vim with the plugin set from the previous dotfiles repository using vim-plug.
13. Installs and configures Pi Coding Agent with the tracked package and default model settings.

## Pi Coding Agent

Pi is installed by `./install.sh` through the existing Node.js/fnm environment. The tracked `pi/settings.json` is symlinked to `~/.pi/agent/settings.json`; it contains the shared default provider, model, thinking level, and package list.

Environment-specific Pi state remains local: provider credentials (`auth.json`), model catalogs (`models-store.json`), sessions, and installed package caches are not tracked or symlinked.

In Fish, `pi` loads the common discovered skills plus Matt Pocock's skills. `pi-superpowers` loads the common discovered skills plus the Superpowers skills and extension. Pi package subcommands such as `pi install`, `pi update`, and `pi list` bypass skill injection so Pi parses them normally. Run `pi-update` to update Pi, installed packages, and both external skill repositories. The skill checkout paths in `pi/skills.conf` are the paths used by the launchers and should be changed together with their shell references.

Run from this directory:

```bash
./install.sh
```

The scripts make user-level font directories. The general shell include is appended at the end of Bash, Zsh, and Fish startup files so its settings override earlier ones. On macOS, Homebrew is bootstrapped noninteractively if it is missing; on Linux, `sudo` is authenticated once for package installation. Python, Node.js, and Rust are installed as user-level toolchain versions rather than replacing operating-system packages; Rustup manages its own shell PATH setup. Each installable tool has its own `scripts/<tool>/install.sh` script, and each script can be run standalone. WSL is treated as Ubuntu for package installation; fonts are installed inside WSL and are not automatically installed on the Windows host. Shell configuration and other dotfiles will be added incrementally.

## Vagrant test VMs

The included `Vagrantfile` boots clean Linux VMs, copies this repository to `/dotfiles`, runs `./install.sh` as the default VM user, and leaves the VM running for inspection.

Prerequisites on the host:

- Vagrant
- A Vagrant provider supported by the selected box, such as VirtualBox, VMware, Parallels, or libvirt
- `vagrant-reload` for the Windows WSL target (`vagrant plugin install vagrant-reload`)

Start a test VM:

```bash
vagrant up ubuntu
# or
vagrant up arch
```

After provisioning completes, inspect the VM with:

```bash
vagrant ssh ubuntu
# or
vagrant ssh arch
```

Reset a VM back to a clean state with:

```bash
vagrant destroy -f ubuntu
vagrant up ubuntu
```

Ubuntu and Arch native Linux are covered by these Vagrant targets.

## Windows WSL test

On a host/provider supported by `gusztavvargadr/windows-11`:

```bash
vagrant up windows-wsl
```

This boots a prebuilt Windows VM, enables WSL2, installs Ubuntu, and runs the dotfiles installer inside Ubuntu WSL. Nested virtualization is required. The Windows 11 box is amd64-only for this target and supports libvirt, VirtualBox, VMware Desktop/Fusion, and Hyper-V; it does not support Parallels or Apple Silicon macOS.
