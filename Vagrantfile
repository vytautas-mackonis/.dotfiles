# frozen_string_literal: true

DOTFILES_TEST_ARCHIVE = "/tmp/dotfiles-vagrant.tar.gz"
system("tar --exclude .git --exclude .vagrant -czf #{DOTFILES_TEST_ARCHIVE} .") || abort("Failed to package dotfiles for Vagrant")

Vagrant.configure("2") do |config|
  # Disable Vagrant's implicit ./ -> /vagrant shared folder; source is copied once below.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provider "libvirt" do |lv|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = "host-model"
    lv.management_network_name = "default"
    lv.management_network_address = "192.168.122.0/24"
  end

  config.vm.provider "tart" do |tart|
    tart.image = "ghcr.io/cirruslabs/macos-sequoia-base:latest"
    tart.name = "dotfiles-macos"
    tart.gui = false
    tart.vnc = false
  end

  machines = {
    "ubuntu" => {
      box: "bento/ubuntu-24.04",
      bootstrap: <<~SHELL
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          ca-certificates curl git sudo ncurses-bin
      SHELL
    },
    "arch" => {
      box: "roboxes/arch",
      bootstrap: <<~SHELL
        if systemctl is-active --quiet systemd-resolved && ! grep -q '^nameserver ' /etc/resolv.conf; then
          sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        fi
        sudo pacman -Sy --needed --noconfirm archlinux-keyring
        sudo pacman -Syu --noconfirm
        sudo pacman -S --needed --noconfirm \
          ca-certificates curl git sudo ncurses
      SHELL
    },
    "macos" => {
      box: "dummy",
      macos: true,
      bootstrap: ""
    },
    "windows-wsl" => {
      box: "gusztavvargadr/windows-11",
      windows: true,
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
      POWERSHELL
    }
  }

  machines.each do |name, machine|
    config.vm.define name do |vm|
      vm.vm.box = machine[:box]
      vm.vm.hostname = "dotfiles-#{name}"

      if machine[:macos]
        vm.ssh.username = "admin"
        vm.ssh.password = "admin"
        vm.ssh.shell = "/bin/sh"
        vm.ssh.insert_key = false
        vm.ssh.private_key_path = []
        vm.vm.provider "tart" do |tart|
          tart.image = "ghcr.io/cirruslabs/macos-sequoia-base:latest"
          tart.name = "dotfiles-macos"
          tart.cpus = 2
          tart.memory = 4096
          tart.disk = 60
          tart.gui = false
          tart.vnc = false
          tart.volumes = ["#{File.expand_path(".")}:tag=dotfiles"]
        end
      end

      if machine[:windows]
        vm.vm.provider "libvirt" do |lv|
          lv.memory = 8192
          lv.cpus = 4
          lv.machine_type = "q35"
          lv.cpu_mode = "custom"
          lv.cpu_model = "EPYC"
          lv.cpu_feature name: "svm", policy: "require"
          lv.nested = true
          %w[relaxed vapic vpindex runtime synic stimer tlbflush frequencies ipi].each do |feature|
            lv.hyperv_feature name: feature, state: "on"
          end
          lv.hyperv_feature name: "spinlocks", state: "on", retries: 8191
          lv.clock_timer name: "hypervclock", present: "yes"
          lv.disk_bus = "sata"
          lv.nic_model_type = "e1000e"
        end
        vm.vm.provider "virtualbox" do |vb|
          vb.memory = 8192
          vb.cpus = 4
        end
        vm.vm.provider "hyperv" do |hv|
          hv.memory = 8192
          hv.cpus = 4
        end
        vm.vm.guest = :windows
        vm.vm.communicator = "winrm"
        vm.vm.provision "file", source: DOTFILES_TEST_ARCHIVE, destination: "C:/dotfiles-vagrant.tar.gz"
        vm.vm.provision "shell", privileged: true, powershell_elevated_interactive: false, inline: machine[:bootstrap]
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "shell", privileged: true, powershell_elevated_interactive: false, inline: <<~POWERSHELL
          $ErrorActionPreference = "Stop"
          $wslReadyMarker = "C:\\.dotfiles-wsl-ready"
          if (Test-Path -LiteralPath $wslReadyMarker) {
            Write-Output "WSL setup already completed; skipping installation."
            exit 0
          }
          $features = @(
            "Microsoft-Windows-Subsystem-Linux",
            "VirtualMachinePlatform"
          )
          foreach ($feature in $features) {
            $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
            if ($state -ne "Enabled") {
              throw "Required Windows feature '$feature' is not enabled after reboot."
            }
          }
          wsl.exe --update --web-download
          if ($LASTEXITCODE -ne 0) {
            throw "Unable to update WSL."
          }
          wsl.exe --set-default-version 2
          $ubuntu = wsl.exe --list --quiet | ForEach-Object { ($_ -replace "`0", "").Trim() } | Where-Object { $_ -eq "Ubuntu" }
          if (-not $ubuntu) {
            wsl.exe --install --distribution Ubuntu --no-launch
            if ($LASTEXITCODE -ne 0) {
              throw "Unable to install Ubuntu WSL2. Check available memory, nested virtualization, and network access."
            }
          }
          New-Item -ItemType File -Path $wslReadyMarker -Force | Out-Null
          Write-Output "WSL setup completed."
        POWERSHELL
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "shell", privileged: false, powershell_elevated_interactive: false, inline: <<~POWERSHELL
          $ErrorActionPreference = "Stop"
          cmd.exe /c "wsl.exe -l -v > C:\\wsl-list.txt 2>&1"
          $wslList = (Get-Content -LiteralPath C:\\wsl-list.txt | Out-String) -replace "`0", "" -replace "`r", ""
          if ($wslList -match "(?m)^\\s*\\*?\\s*Ubuntu\\s+Running\\s+1\\s*$" -or $wslList -match "(?m)^\\s*\\*?\\s*Ubuntu\\s+Stopped\\s+1\\s*$") {
            throw "Ubuntu WSL distribution is WSL1; enable WSL2 and retry. Output: $wslList"
          }
          if ($wslList -notmatch "(?m)^\\s*\\*?\\s*Ubuntu\\s+(Running|Stopped)\\s+2\\s*$") {
            throw "Ubuntu WSL distribution is missing or is not version 2. Output: $wslList"
          }
          Write-Output "WSL Ubuntu is available"
          $wslArchive = "/mnt/c/dotfiles-vagrant.tar.gz"
          cmd.exe /c 'wsl.exe -d Ubuntu -- bash -c "rm -rf /dotfiles && mkdir -p /dotfiles" > C:\\wsl-prepare.txt 2>&1'
          if ($LASTEXITCODE -ne 0) {
            throw "Unable to prepare /dotfiles in WSL Ubuntu."
          }
          $wslBatch = @'
@echo off
wsl.exe -d Ubuntu -- bash -c "set -e; tar -xzf /mnt/c/dotfiles-vagrant.tar.gz -C /dotfiles; cd /dotfiles; ./install.sh; source /root/.bash_profile" > C:\\wsl-output.txt 2>&1
exit /b %ERRORLEVEL%
'@
          Set-Content -LiteralPath C:\\dotfiles-wsl.cmd -Value $wslBatch -Encoding ASCII
          cmd.exe /c C:\\dotfiles-wsl.cmd
          $wslExitCode = $LASTEXITCODE
          Get-Content -LiteralPath C:\\wsl-output.txt
          if ($wslExitCode -ne 0) {
            throw "Dotfiles installation failed inside WSL Ubuntu."
          }
        POWERSHELL
      else
        dotfiles_dir = machine[:macos] ? "/Users/admin/dotfiles" : "/dotfiles"
        if machine[:macos]
          vm.vm.provision "shell", privileged: false, inline: <<~SHELL
            set -eux
            printf '%s\\n' admin | sudo -S -p '' sh -c 'grep -q "^admin ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers || printf "%s\\n" "admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
            sudo -n true
            sudo mkdir -p #{dotfiles_dir}
            if ! mount | grep -q "on #{dotfiles_dir} "; then
              sudo mount_virtiofs dotfiles #{dotfiles_dir}
            fi
            cd #{dotfiles_dir}
            /bin/zsh -lic './install.sh'
          SHELL
        else
          vm.vm.provision "file", source: DOTFILES_TEST_ARCHIVE, destination: "/tmp/dotfiles.tar.gz"
          vm.vm.provision "shell", privileged: false, inline: <<~SHELL
            set -eux
            sudo rm -rf #{dotfiles_dir}
            sudo mkdir -p #{dotfiles_dir}
            sudo chown "$USER:$USER" #{dotfiles_dir}
            tar -xzf /tmp/dotfiles.tar.gz -C #{dotfiles_dir}
            #{machine[:bootstrap]}
            cd #{dotfiles_dir}
            ./install.sh
          SHELL
        end
      end
    end
  end
end
