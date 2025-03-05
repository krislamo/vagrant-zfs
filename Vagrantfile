# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
settings_path = '.vagrant.yml'
settings = {}

if File.exist?(settings_path)
  settings = YAML.load_file(settings_path)
end

VAGRANT_NAME = settings['VAGRANT_NAME'] || 'zfstest'
VAGRANT_BOX  = settings['VAGRANT_BOX']  || 'debian/bookworm64'
VAGRANT_PROV = settings['VAGRANT_PROV'] || true
VAGRANT_CPUS = settings['VAGRANT_CPUS'] || 4
VAGRANT_MEM  = settings['VAGRANT_MEM']  || 4096
VAGRANT_SH   = settings['VAGRANT_SH']   || ''
NUM_DISKS    = settings['NUM_DISKS']    || 16
DISK_SIZE    = settings['DISK_SIZE']    || '18T'

Vagrant.configure("2") do |config|
  config.vm.box = VAGRANT_BOX
  config.vm.hostname = VAGRANT_NAME
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ".git"

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
        :size => "#{DISK_SIZE}", \
        :type => 'qcow2', \
        :sparse => true, \
        :device => "vdz#{device_suffix}", \
        :serial => "VDZ#{device_suffix.upcase}"
      end
    end

  if VAGRANT_PROV
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

  if VAGRANT_SH != ''
    config.vm.provision "shell", inline: <<-SHELL
      if [ -f /vagrant/scratch/#{VAGRANT_SH} ]; then
        /bin/bash /vagrant/scratch/#{VAGRANT_SH}
      else
        echo "ERROR: /vagrant/scratch/#{VAGRANT_SH} not found"
        exit 1
      fi
    SHELL
  end
end
