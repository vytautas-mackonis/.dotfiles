# Windows WSL Vagrant Testing Design

## Purpose

Add an automated Vagrant target that boots a prebuilt Windows box, enables WSL2, installs Ubuntu inside WSL, copies the current dotfiles checkout into WSL, and runs the same installer verification used by the native Ubuntu and Arch targets.

The goal is to test the dotfiles' Ubuntu-on-WSL behavior. Windows itself is not a desired-state target.

## Scope

### In scope

- A new `windows-wsl` Vagrant machine definition.
- Use of the prebuilt `gusztavvargadr/windows-10` box.
- Provider artifacts for libvirt, VirtualBox, VMware Desktop/Fusion, and Hyper-V where the box supports them.
- Windows provisioning for WSL2 and the Ubuntu distribution.
- Transfer and execution of the repository inside Ubuntu WSL.
- Shared verification for installed commands and managed dotfiles state.
- Documentation of provider, architecture, and nested-virtualization requirements.

### Out of scope

- Building a Windows box from an ISO.
- Testing Windows configuration itself.
- Parallels support for the Windows 10 box.
- Apple Silicon support for the amd64-only Windows 10 box.
- Replacing the existing native Ubuntu and Arch targets.

## Architecture

The existing `ubuntu` and `arch` machines remain unchanged. A separate `windows-wsl` target uses the Windows box and runs two provisioning layers:

1. **Windows layer:** enable the WSL and Virtual Machine Platform optional features, configure WSL2 as the default, reboot when required, and ensure Ubuntu is installed.
2. **WSL layer:** execute commands through `wsl.exe -d Ubuntu -- bash -lc`, copy the repository into the WSL filesystem, run `./install.sh`, and run shared verification.

The Windows target must use the provider-specific box artifact selected by Vagrant. The default development provider on this Linux host is libvirt; compatible Intel macOS hosts may use VirtualBox or VMware Fusion/Desktop; Hyper-V is available on Windows hosts. The Vagrantfile should avoid provider-specific settings unless required and should fail clearly when the selected provider has no matching box artifact.

## Provisioning flow

1. Package the checkout, excluding `.git` and `.vagrant`, using the existing archive approach.
2. Boot `gusztavvargadr/windows-10`.
3. Enable `Microsoft-Windows-Subsystem-Linux` and `VirtualMachinePlatform` through elevated PowerShell.
4. Configure WSL2 as the default version and reboot if Windows reports a restart is required.
5. Install or initialize the Ubuntu distribution. Provisioning must be safe to repeat and must not reinstall an existing Ubuntu distribution unnecessarily.
6. From Windows, verify that `wsl.exe -l -v` reports the Ubuntu distribution at version 2, then verify that `wsl.exe -d Ubuntu -- bash -lc ...` can execute Bash commands.
7. Transfer the archive into Ubuntu WSL, extract it into a controlled path, and run `./install.sh`.
8. Run the shared verification script inside WSL.

The flow must fail rather than silently continuing when WSL is unavailable, Ubuntu cannot start, or the distribution is WSL1.

## Shared verification

Create a repository script for environment verification so native Ubuntu, Arch, and WSL Ubuntu use the same assertions where applicable. It should verify:

- `python`, `python3`, `node`, `npm`, `bun`, `deno`, `fzf`, `podman`, `tmux`, and `vim` are discoverable.
- `~/.vim/vimrc` points to the current checkout and Vim plugins are present/synchronized.
- `~/.tmux.conf` points to the current checkout.
- TPM and declared tmux plugins exist.
- `.inputrc` has exactly one effective `set bell-style none` line at the end.

Checks that are not meaningful inside WSL should remain in the native target-specific provisioning, not be forced into the shared script.

## Idempotency and desired state

Repeated provisioning should converge rather than accumulate state:

- WSL feature enablement and Ubuntu installation detect existing state.
- Repository extraction replaces the prior test checkout safely.
- Existing installer scripts remain responsible for convergence inside WSL.
- Verification runs after every provisioning attempt and returns nonzero on drift or failure.

## Error handling

- PowerShell and WSL commands run with explicit failure checking.
- Reboot handling must be explicit and bounded; a failed reboot or unavailable service stops provisioning.
- WSL commands must use the intended Ubuntu distribution explicitly rather than relying on the default distribution.
- Provider incompatibility, missing nested virtualization, unsupported architecture, and WSL1 fallback must produce actionable errors.

## Testing matrix

- Linux host + libvirt + Windows 10 box + WSL2 Ubuntu: required test for this repository.
- Intel macOS + VirtualBox or VMware Fusion: supported by the box and documented, but not runnable in the current environment.
- Windows host + Hyper-V: supported by the box and documented, but not runnable in the current environment.
- Apple Silicon macOS and Parallels: documented as unsupported for this Windows 10 box.
- Existing native Ubuntu and Arch Vagrant targets continue to run.

## Documentation

Update `README.md` with:

- `vagrant up windows-wsl` usage.
- Required nested virtualization and provider prerequisites.
- The Windows box/provider and architecture limitations.
- The fact that provisioning tests Ubuntu WSL, not Windows desired state.
