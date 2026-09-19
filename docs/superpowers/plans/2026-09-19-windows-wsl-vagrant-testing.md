# Windows WSL Vagrant Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a provider-portable Vagrant target that provisions WSL2 Ubuntu inside a prebuilt Windows VM and runs the dotfiles installer and convergence checks there.

**Architecture:** Keep native Ubuntu and Arch targets intact. Add a `windows-wsl` target using `gusztavvargadr/windows-10`; provision Windows features and Ubuntu WSL2 through PowerShell, then run the repository and shared verification script through `wsl.exe -d Ubuntu -- bash -lc`. Use a shared verification script for native Linux and WSL environments.

**Tech Stack:** Vagrant 2.x, Vagrant Cloud Windows box, libvirt/VirtualBox/VMware Desktop/Hyper-V provider artifacts, PowerShell, WSL2, Ubuntu, Bash.

**Spec:** `docs/superpowers/specs/2026-09-19-windows-wsl-vagrant-testing-design.md`

## Global Constraints

- Use the prebuilt `gusztavvargadr/windows-10` box; do not build a Windows box from an ISO.
- Test Ubuntu-on-WSL behavior; Windows itself is not a desired-state target.
- Fail when WSL is unavailable, Ubuntu cannot start, or the distribution is WSL1.
- Keep native Ubuntu and Arch Vagrant targets working.
- Treat repeated provisioning as convergence: do not reinstall an existing Ubuntu distribution unnecessarily.
- Support provider artifacts listed by the box: libvirt, VirtualBox, VMware Desktop/Fusion, and Hyper-V.
- Document that the Windows 10 box is amd64-only and does not support Parallels or Apple Silicon macOS.

## Review Focus

- **Required reboot after enabling Windows features:** the provisioning flow must reconnect and continue rather than report success before WSL is usable; test in the Windows target task with a post-reboot WSL probe.
- **WSL1 fallback:** an Ubuntu distribution that exists but reports version 1 must fail; test the WSL version parser with representative `wsl.exe -l -v` output.
- **Distribution names containing spaces or CRLF output:** PowerShell output must be passed safely to WSL; test the command construction with the fixed `Ubuntu` distribution name and normalized output.
- **Repeated provisioning:** an existing Ubuntu distribution must be reused and the repository checkout replaced safely; test by provisioning the target twice and checking the second run succeeds without reinstalling the distro.
- **Provider mismatch/architecture:** unsupported provider selection must fail with an actionable message; test provider metadata/README instructions and keep the target’s provider list explicit.
- **Reboot support:** require the `vagrant-reload` plugin and document its installation before `vagrant up windows-wsl`.

---

### Task 1: Add shared WSL/native installation verification

**Files:**
- Create: `tests/verify-install.sh`
- Modify: `Vagrantfile` provisioning commands for `ubuntu` and `arch`
- Modify: `tests/install_structure_test.sh`

**Interfaces:**
- Produces executable `tests/verify-install.sh`.
- Consumes `DOTFILES_DIR` and the current user’s home directory.
- Returns zero only when all required commands and managed-state assertions pass.

- [ ] **Step 1: Write the failing structural test**

Extend `tests/install_structure_test.sh` with:

```bash
assert_executable tests/verify-install.sh
assert_contains tests/verify-install.sh 'command -v python'
assert_contains tests/verify-install.sh 'command -v node'
assert_contains tests/verify-install.sh 'readlink "$HOME/.vim/vimrc"'
assert_contains tests/verify-install.sh 'readlink "$HOME/.tmux.conf"'
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
tests/install_structure_test.sh
```

Expected: FAIL because `tests/verify-install.sh` does not exist.

- [ ] **Step 3: Implement the verification script**

Create an executable Bash script with `set -euo pipefail` that:

```bash
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
```

Use the repository path supplied through `DOTFILES_DIR`; the Vagrant target must set it to the extracted checkout path before invocation.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
tests/install_structure_test.sh
bash -n tests/verify-install.sh
```

Expected: PASS.

- [ ] **Step 5: Call the shared verifier from native targets**

Modify the existing Ubuntu and Arch inline provisioning after `./install.sh`:

```bash
cd /dotfiles
./install.sh
export DOTFILES_DIR=/dotfiles
./tests/verify-install.sh
```

- [ ] **Step 6: Run native integration checks**

Run:

```bash
vagrant provision ubuntu
vagrant provision arch
```

Expected: both provisioning runs finish with `Desired-state verification passed.`

- [ ] **Step 7: Commit**

```bash
git add tests/verify-install.sh tests/install_structure_test.sh Vagrantfile
git commit -m "Add shared desired-state verification"
```

### Task 2: Add the Windows WSL Vagrant target and idempotent Windows provisioning

**Files:**
- Modify: `Vagrantfile`
- Modify: `tests/install_structure_test.sh`

**Interfaces:**
- Produces Vagrant machine `windows-wsl` using box `gusztavvargadr/windows-10`.
- Uses Windows PowerShell provisioners for feature setup and WSL initialization.
- Leaves the Ubuntu/Arch machine definitions unchanged except for shared verification invocation.

- [ ] **Step 1: Write the failing structural test**

Add assertions:

```bash
assert_contains Vagrantfile '"windows-wsl"'
assert_contains Vagrantfile 'gusztavvargadr/windows-10'
assert_contains Vagrantfile 'Microsoft-Windows-Subsystem-Linux'
assert_contains Vagrantfile 'VirtualMachinePlatform'
assert_contains Vagrantfile 'wsl.exe -l -v'
assert_contains Vagrantfile 'wsl.exe -d Ubuntu'
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
tests/install_structure_test.sh
```

Expected: FAIL because the Windows target and provisioning commands do not exist.

- [ ] **Step 3: Add the Windows machine definition**

Add a `windows-wsl` entry to the existing `machines` map:

```ruby
"windows-wsl" => {
  box: "gusztavvargadr/windows-10",
  bootstrap: <<~POWERSHELL
    $ErrorActionPreference = "Stop"
    $features = @(
      "Microsoft-Windows-Subsystem-Linux",
      "VirtualMachinePlatform"
    )
    foreach ($feature in $features) {
      $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
      if ($state -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
      }
    }
    wsl.exe --set-default-version 2
  POWERSHELL
}
```

Use the existing `config.vm.define` loop, but select the Windows communicator/provisioning path for this machine. Do not make Linux shell bootstrap commands run against Windows.

- [ ] **Step 4: Enable WSL2 features idempotently**

In the Windows bootstrap, use PowerShell commands that:

```powershell
$ErrorActionPreference = "Stop"

$features = @(
  "Microsoft-Windows-Subsystem-Linux",
  "VirtualMachinePlatform"
)
foreach ($feature in $features) {
  $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
  if ($state -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
  }
}
wsl.exe --set-default-version 2
```

Add `vagrant-reload` as a documented prerequisite and use its `reload` provisioner after feature enablement, with a bounded delay, so Vagrant reconnects before the Ubuntu setup provisioner runs. The post-reload provisioner must rerun the feature-state checks rather than assuming the reboot completed successfully.

- [ ] **Step 5: Install/reuse Ubuntu without destructive reinstall**

Use PowerShell to detect the distribution first:

```powershell
$ubuntu = wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq "Ubuntu" }
if (-not $ubuntu) {
  wsl.exe --install --distribution Ubuntu --no-launch
}
```

After any required reboot, wait for and verify Ubuntu:

```powershell
$wslList = wsl.exe --list --verbose
if ($wslList -notmatch "(?m)^\s*Ubuntu\s+Running|Stopped\s+2\s*$") {
  throw "Ubuntu WSL distribution is missing or is not version 2. Output: $wslList"
}
wsl.exe -d Ubuntu -- bash -lc "printf 'WSL Ubuntu is available\n'"
```

Normalize CRLF output before matching. If Ubuntu reports version 1, throw an actionable error rather than upgrading implicitly.

- [ ] **Step 6: Run the structural test**

Run:

```bash
tests/install_structure_test.sh
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Vagrantfile tests/install_structure_test.sh
git commit -m "Add Windows WSL Vagrant target"
```

### Task 3: Transfer the repository and run the installer inside WSL

**Files:**
- Modify: `Vagrantfile`
- Modify: `README.md`
- Modify: `tests/install_structure_test.sh`

**Interfaces:**
- Consumes the archive created by `DOTFILES_TEST_ARCHIVE`.
- Runs commands through `wsl.exe -d Ubuntu -- bash -lc`.
- Produces a successful `windows-wsl` provision only after installer and shared verification both return zero.

- [ ] **Step 1: Write the failing structural test**

Add assertions:

```bash
assert_contains Vagrantfile 'DOTFILES_TEST_ARCHIVE'
assert_contains Vagrantfile 'tar -xzf'
assert_contains Vagrantfile 'tests/verify-install.sh'
assert_contains README.md 'vagrant up windows-wsl'
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
tests/install_structure_test.sh
```

Expected: FAIL because the WSL transfer/test commands and README usage do not exist.

- [ ] **Step 3: Add WSL repository transfer and execution**

Add a Windows-specific file provisioner that copies `DOTFILES_TEST_ARCHIVE` to `C:/dotfiles-vagrant.tar.gz`. After Ubuntu is verified, run these PowerShell commands:

```powershell
$archive = "C:\dotfiles-vagrant.tar.gz"
$wslArchive = "/tmp/dotfiles-vagrant.tar.gz"

wsl.exe -d Ubuntu -- bash -lc "rm -rf /dotfiles && mkdir -p /dotfiles"
Get-Content -LiteralPath $archive -Encoding Byte | wsl.exe -d Ubuntu -- bash -lc "cat > $wslArchive"
wsl.exe -d Ubuntu -- bash -lc "tar -xzf $wslArchive -C /dotfiles && cd /dotfiles && ./install.sh && export DOTFILES_DIR=/dotfiles && ./tests/verify-install.sh"
```

Ensure the WSL command uses `bash -lc` so shell initialization does not alter the test unexpectedly and so the command exits with the installer’s status.

- [ ] **Step 4: Document usage and limitations**

Add to `README.md`:

```markdown
## Windows WSL test

On a host/provider supported by `gusztavvargadr/windows-10`:

```bash
vagrant up windows-wsl
```

This boots a prebuilt Windows VM, enables WSL2, installs Ubuntu, and runs the dotfiles installer inside Ubuntu WSL. Nested virtualization is required. The Windows 10 box is amd64-only and supports libvirt, VirtualBox, VMware Desktop/Fusion, and Hyper-V; it does not support Parallels or Apple Silicon macOS.
```

- [ ] **Step 5: Run structural and syntax checks**

Run:

```bash
tests/install_structure_test.sh
bash -n tests/verify-install.sh
```

Expected: PASS.

- [ ] **Step 6: Run the complete native matrix**

Run:

```bash
vagrant provision ubuntu
vagrant provision arch
```

Expected: both native targets pass shared verification.

- [ ] **Step 7: Run the Windows WSL target**

On a host with a supported provider and nested virtualization:

```bash
vagrant up windows-wsl
vagrant provision windows-wsl
```

Expected: first run provisions Windows/WSL and passes shared verification; second run reuses Ubuntu, does not reinstall the distribution, reruns `./install.sh`, and passes shared verification again.

- [ ] **Step 8: Commit**

```bash
git add Vagrantfile README.md tests/install_structure_test.sh
git commit -m "Run dotfiles tests inside Windows WSL"
```

### Task 4: Final validation and PR

**Files:**
- Modify: none unless validation identifies a concrete issue.

- [ ] **Step 1: Run all repository-local checks**

```bash
tests/install_structure_test.sh
find . -path './.git' -prune -o -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

- [ ] **Step 2: Run native Vagrant verification**

```bash
vagrant provision ubuntu
vagrant provision arch
```

- [ ] **Step 3: Run Windows WSL verification on the available libvirt host**

```bash
vagrant provision windows-wsl
vagrant provision windows-wsl
```

The second run is required to demonstrate convergence.

- [ ] **Step 4: Review the final diff and status**

```bash
git diff master...HEAD --check
git status --short
git log --oneline master..HEAD
```

Expected: no whitespace errors, intended files only, and all required commits present.

- [ ] **Step 5: Push and create the PR**

```bash
git push -u origin <feature-branch>
gh pr create --base master --head <feature-branch> --title "Test dotfiles inside Windows WSL" --body-file /tmp/pr-body.md
```

The PR body must include the provider limitations and the exact native/Windows verification commands that passed.
