# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
settings_path = '.vagrant.yml'
settings = {}

if File.exist?(settings_path)
  settings = YAML.load_file(settings_path)
end

VAGRANT_BOX  = settings['VAGRANT_BOX']  || 'debian/bookworm64'
VAGRANT_CPUS = settings['VAGRANT_CPUS'] || 4
VAGRANT_MEM  = settings['VAGRANT_MEM']  || 4096
NUM_DISKS    = settings['NUM_DISKS']    || 12
DISK_SIZE    = settings['DISK_SIZE']    || 1024

Vagrant.configure("2") do |config|
  config.vm.box = VAGRANT_BOX

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus   = VAGRANT_CPUS
    libvirt.memory = VAGRANT_MEM
    # Doesn't boot without this on rockylinux/9
    libvirt.machine_virtual_size = 10

    (1..NUM_DISKS).each do |i|
      if i <= 676
        first_char = (97 + ((i - 1) / 26)).chr
        second_char = (97 + ((i - 1) % 26)).chr
        device_suffix = first_char + second_char
      else
        raise "Error: Exceeded number of supported disks (#{NUM_DISKS}/676))"
      end

      libvirt.storage :file, \
        :size => "#{DISK_SIZE}M", \
        :type => 'raw', \
        :device => "vdz#{device_suffix}"
      end
    end

  config.vm.provision "shell", inline: <<-SHELL
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID=$ID
    else
      echo "Cannot detect OS, exiting"
      exit 1
    fi

    if [ "$OS_ID" = "debian" ]; then
      export DEBIAN_FRONTEND=noninteractive
      SOURCES_LIST="/etc/apt/sources.list.d/contrib.list"
      echo "deb http://deb.debian.org/debian/ ${VERSION_CODENAME} contrib" > "$SOURCES_LIST"
      apt-get update
      apt-get install -y linux-headers-$(uname -r)
      apt-get install -y zfsutils-linux
    elif [ "$OS_ID" = "rocky" ]; then
      dnf install -y epel-release
      dnf config-manager --enable epel
      dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
      dnf config-manager --disable zfs
      dnf config-manager --enable zfs-kmod
      dnf install -y zfs
    else
      echo "Unsupported OS: $OS_ID"
      exit 1
    fi
  SHELL
end
