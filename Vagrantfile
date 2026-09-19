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
        sudo pacman -Sy --needed --noconfirm archlinux-keyring
        sudo pacman -Syu --noconfirm
        sudo pacman -S --needed --noconfirm \
          ca-certificates curl git sudo ncurses
      SHELL
    }
  }

  machines.each do |name, machine|
    config.vm.define name do |vm|
      vm.vm.box = machine[:box]
      vm.vm.hostname = "dotfiles-#{name}"

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
      SHELL
    end
  end
end
