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
    "windows-wsl" => {
      box: "gusztavvargadr/windows-10",
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
        wsl.exe --set-default-version 2
      POWERSHELL
    }
  }

  machines.each do |name, machine|
    config.vm.define name do |vm|
      vm.vm.box = machine[:box]
      vm.vm.hostname = "dotfiles-#{name}"

      if machine[:windows]
        vm.vm.communicator = "winrm"
        vm.vm.provision "file", source: DOTFILES_TEST_ARCHIVE, destination: "C:/dotfiles-vagrant.tar.gz"
        vm.vm.provision "powershell", inline: machine[:bootstrap]
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "powershell", inline: <<~POWERSHELL
          $ErrorActionPreference = "Stop"
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
          wsl.exe --set-default-version 2
          $ubuntu = wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq "Ubuntu" }
          if (-not $ubuntu) {
            wsl.exe --install --distribution Ubuntu --no-launch
          }
        POWERSHELL
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "powershell", inline: <<~POWERSHELL
          $ErrorActionPreference = "Stop"
          $wslList = (wsl.exe -l -v | Out-String) -replace "`r", ""
          if ($wslList -match "(?m)^\\s*Ubuntu\\s+Running\\s+1\\s*$" -or $wslList -match "(?m)^\\s*Ubuntu\\s+Stopped\\s+1\\s*$") {
            throw "Ubuntu WSL distribution is WSL1; enable WSL2 and retry. Output: $wslList"
          }
          if ($wslList -notmatch "(?m)^\\s*Ubuntu\\s+(Running|Stopped)\\s+2\\s*$") {
            throw "Ubuntu WSL distribution is missing or is not version 2. Output: $wslList"
          }
          wsl.exe -d Ubuntu -- bash -lc "printf 'WSL Ubuntu is available\\n'"
        POWERSHELL
      else
        vm.vm.provision "file", source: DOTFILES_TEST_ARCHIVE, destination: "/tmp/dotfiles.tar.gz"
        vm.vm.provision "shell", privileged: false, inline: <<~SHELL
          set -eux
          sudo rm -rf /dotfiles
          sudo mkdir -p /dotfiles
          sudo chown "$USER:$USER" /dotfiles
          tar -xzf /tmp/dotfiles.tar.gz -C /dotfiles
          #{machine[:bootstrap]}
          cd /dotfiles
          ./install.sh
          export DOTFILES_DIR=/dotfiles
          ./tests/verify-install.sh
        SHELL
      end
    end
  end
end
