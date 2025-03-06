# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
settings_path = '.vagrant.yml'
settings = {}

if File.exist?(settings_path)
  settings = YAML.load_file(settings_path)
end

# Can't use `||` here because `false || true` evaluates to true
VAGRANT_PROV  = settings.key?('VAGRANT_PROV') ? settings['VAGRANT_PROV'] : true
VAGRANT_NODES = settings['VAGRANT_NODES'] || 1
VAGRANT_NAME  = settings['VAGRANT_NAME'] || 'zfstest'
VAGRANT_BOX   = settings['VAGRANT_BOX']  || 'debian/bookworm64'
VAGRANT_CPUS  = settings['VAGRANT_CPUS'] || 4
VAGRANT_MEM   = settings['VAGRANT_MEM']  || 4096
VAGRANT_SH    = settings['VAGRANT_SH']   || ''
NUM_DISKS     = settings['NUM_DISKS']    || 16
# 18 TB decimal/SI to binary/IEC conversion
# 18 TB x (1000^4 / 1024^4) = 16.37 TiB
# 16.37 TiB x 1024 = ~16763 GiB
DISK_SIZE     = settings['DISK_SIZE']    || '16763G'

NODES = settings['NODES'] || {}

Vagrant.configure("2") do |config|
  config.vm.box = VAGRANT_BOX
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ".git"

  HOSTS = Array(1..VAGRANT_NODES)
  HOSTS.each do |count|
    DEFAULT_NODE_NAME = "#{VAGRANT_NAME}#{count}"
    NODE_NAME = NODES.dig(DEFAULT_NODE_NAME, 'NAME') || DEFAULT_NODE_NAME

    config.vm.define NODE_NAME do |node_config|
      node_config.vm.hostname = NODE_NAME
      node_config.vm.box = NODES.dig(DEFAULT_NODE_NAME, 'BOX') || VAGRANT_BOX

      node_config.vm.provider :libvirt do |libvirt|
        libvirt.cpus   = NODES.dig(DEFAULT_NODE_NAME, 'CPUS') || VAGRANT_CPUS
        libvirt.memory = NODES.dig(DEFAULT_NODE_NAME, 'MEM') || VAGRANT_MEM
        # Doesn't boot without this on rockylinux/9
        libvirt.machine_virtual_size = 10

        NODE_DISKS = NODES.dig(DEFAULT_NODE_NAME, 'DISKS') || {}
        NODE_NUM_DISKS = NODE_DISKS['NUM'] || NUM_DISKS
        NODE_DISK_SIZE = NODE_DISKS['SIZE'] || DISK_SIZE

        if !NODE_DISKS.key?('VAGRANT_DISKS') || NODE_DISKS['VAGRANT_DISKS']
          (1..NODE_NUM_DISKS).each do |i|
            if i <= 676
              FIRST_CHAR = (97 + ((i - 1) / 26)).chr
              SECOND_CHAR = (97 + ((i - 1) % 26)).chr
              DEVICE_SUFFIX = FIRST_CHAR + SECOND_CHAR
            else
              raise "Error: Exceeded number of supported disks (#{NODE_NUM_DISKS}/676))"
            end

            libvirt.storage :file, \
              :size => "#{NODE_DISK_SIZE}", \
              :type => 'qcow2', \
              :sparse => true, \
              :device => "vdz#{DEVICE_SUFFIX}", \
              :serial => "VDZ#{DEVICE_SUFFIX.upcase}"
          end
        end

        if NODE_DISKS.key?('CUSTOM')
          CUSTOM_DISKS = NODE_DISKS['CUSTOM']
          CUSTOM_DISKS.each do |disk|
            libvirt.storage :file, \
              :size => disk['SIZE'] || NODE_DISK_SIZE, \
              :type => disk['TYPE'] || 'qcow2', \
              :sparse => disk.key?('SPARSE') ? disk['SPARSE'] : true, \
              :device => disk['DEVICE'], \
              :serial => disk['SERIAL'] || disk['DEVICE'].upcase
          end
        end
      end

      NODE_PROV = NODES.dig(DEFAULT_NODE_NAME, 'PROV')
      if NODE_PROV.nil? ? VAGRANT_PROV : NODE_PROV
        node_config.vm.provision "shell", path: "provision.sh"
      end

      NODE_SH = NODES.dig(DEFAULT_NODE_NAME, 'SH') || VAGRANT_SH
      if NODE_SH != ''
        node_config.vm.provision "shell", inline: <<-SHELL
          if [ -f /vagrant/scratch/#{NODE_SH} ]; then
            /bin/bash /vagrant/scratch/#{NODE_SH}
          else
            echo "ERROR: /vagrant/scratch/#{NODE_SH} not found"
            exit 1
          fi
        SHELL
      end
    end
  end
end
