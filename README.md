# Vagrant ZFS

This repository contains Vagrant configuration using the libvirt provider to
create a virtual ZFS environment for testing purposes.

The setup leverages sparse qcow2 files to simulate large virtual disks
(18TB each by default) for testing ZFS. These virtual disks only consume actual
host storage space when data is written to them, with each empty disk requiring
only 2-3MB of real space. This allows you to experiment with massive albeit
empty ZFS arrays without needing equivalent physical storage resources.

By default, the Vagrant VM will be configured with:

- 4 vCPU cores
- 4 GB of RAM
- 16 virtual disks (default size of 18TB each, sparse disks)

## Quick Start

This quickstart demonstrates using zfs-kmod on Rocky Linux 9. Many professional
environments standardize on RHEL-based infrastructure, making Rocky Linux an
excellent choice for testing ZFS in enterprise-like settings. Get your test
environment up and running with these steps:

- Reset the environment if needed
  ```
  vagrant destroy -f
  ```
- (Optional) override the `VAGRANT_BOX` to Rocky Linux
  ```
  echo "VAGRANT_BOX: rockylinux/9" > .vagrant.yml
  ```
- Bring up the VM
  ```
  vagrant up
  ```
- After booting, login to the VM
  ```
  vagrant ssh
  ```
- Look at `/etc/os-release` to double check you are on Rocky Linux
  ```
  cat /etc/os-release
  ```
- Load the ZFS module (already loaded by default on Debian)
  ```
  lsmod | grep zfs
  sudo modprobe zfs
  lsmod | grep zfs
  ```
- Verify no pools exist and identify the persistent device names to use

  ```
  lsblk
  zpool status
  ls -al /dev/disk/by-id/
  ```

- Create a ZFS pool of 2x raidz2 vdevs with a spare disk
  ```
  sudo zpool create \
    -o ashift=12 \
    -O compression=lz4 \
    -O canmount=off \
    -O mountpoint=none \
    tank \
    raidz2 /dev/disk/by-id/virtio-VDZA{A..E} \
    raidz2 /dev/disk/by-id/virtio-VDZA{F..J} \
    spare /dev/disk/by-id/virtio-VDZAK
  ```
- Check the disks and zpool
  ```
  lsblk
  zpool status
  zfs list
  ```
- Create and mount a dataset
  ```
  sudo zfs create -o mountpoint=/srv/test tank/test
  zfs list
  ```
- Add another vdev
  ```
  sudo zpool add tank raidz2 /dev/disk/by-id/virtio-VDZA{L..P}
  zpool status
  zfs list
  ```

## Configuration Overrides

You can override the default settings by creating a `.vagrant.yml` file with
the following available settings:

- `VAGRANT_NAME`
  - Default: `zfstest`
  - The hostname for the virtual machine
- `VAGRANT_BOX`
  - Default: `debian/bookworm64`
  - Also tested with `rockylinux/9`
- `VAGRANT_PROV`
  - Default: `true`
  - Whether to provision the VM with ZFS packages
- `VAGRANT_CPUS`
  - Default: `4`
  - Number of vCPU cores for the VM
- `VAGRANT_MEM`
  - Default: `4096` (4 GB)
  - Memory allocation for the VM in MB
- `VAGRANT_SH`
  - Default: (empty)
  - Optional shell script in ./scratch to run during provisioning
- `NUM_DISKS`
  - Default: `16`
  - Number of virtual disks to create (max 676)
- `DISK_SIZE`
  - Default: `18T`
  - Size of each virtual disk (sparse allocation)

## Copyright and License

Copyright (C) 2025 Kris Lamoureux

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.
