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

      if machine[:windows]
        vm.vm.provider "libvirt" do |lv|
          lv.memory = 8192
          lv.cpus = 4
          lv.machine_type = "q35"
          lv.cpu_mode = "host-passthrough"
          lv.nested = true
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
        vm.vm.provision "shell", privileged: false, powershell_elevated_interactive: false, inline: machine[:bootstrap]
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "shell", privileged: false, powershell_elevated_interactive: false, inline: <<~POWERSHELL
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
            wsl.exe --install --web-download --distribution Ubuntu
            if ($LASTEXITCODE -ne 0) {
              throw "Unable to install Ubuntu WSL2. Check available memory, nested virtualization, and network access."
            }
          }
        POWERSHELL
        vm.vm.provision "reload", reboot: true, delay: 10
        vm.vm.provision "shell", privileged: false, powershell_elevated_interactive: false, inline: <<~POWERSHELL
          $ErrorActionPreference = "Stop"
          $wslList = (wsl.exe -l -v | Out-String) -replace "`r", ""
          if ($wslList -match "(?m)^\\s*\\*?\\s*Ubuntu\\s+Running\\s+1\\s*$" -or $wslList -match "(?m)^\\s*\\*?\\s*Ubuntu\\s+Stopped\\s+1\\s*$") {
            throw "Ubuntu WSL distribution is WSL1; enable WSL2 and retry. Output: $wslList"
          }
          if ($wslList -notmatch "(?m)^\\s*\\*?\\s*Ubuntu\\s+(Running|Stopped)\\s+2\\s*$") {
            throw "Ubuntu WSL distribution is missing or is not version 2. Output: $wslList"
          }
          wsl.exe -d Ubuntu -- bash -lc "printf 'WSL Ubuntu is available\\n'"
          if ($LASTEXITCODE -ne 0) {
            throw "Unable to execute a command in WSL Ubuntu."
          }
          $archive = "C:\\dotfiles-vagrant.tar.gz"
          $wslArchive = "/tmp/dotfiles-vagrant.tar.gz"
          wsl.exe -d Ubuntu -- bash -lc "rm -rf /dotfiles && mkdir -p /dotfiles"
          if ($LASTEXITCODE -ne 0) {
            throw "Unable to prepare /dotfiles in WSL Ubuntu."
          }
          Get-Content -LiteralPath $archive -Encoding Byte | wsl.exe -d Ubuntu -- bash -lc "cat > $wslArchive"
          if ($LASTEXITCODE -ne 0) {
            throw "Unable to transfer the dotfiles archive into WSL Ubuntu."
          }
          wsl.exe -d Ubuntu -- bash -lc "tar -xzf $wslArchive -C /dotfiles && cd /dotfiles && ./install.sh && export DOTFILES_DIR=/dotfiles && ./tests/verify-install.sh"
          if ($LASTEXITCODE -ne 0) {
            throw "Dotfiles installation or desired-state verification failed inside WSL Ubuntu."
          }
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
