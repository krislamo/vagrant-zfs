#!/bin/bash
if [ -f /etc/os-release ]; then
	# shellcheck source=/dev/null
	. /etc/os-release
	OS_ID=$ID
else
	echo "Cannot detect OS, exiting"
	exit 1
fi

if [ "$OS_ID" = "debian" ]; then
	export DEBIAN_FRONTEND=noninteractive
	SOURCES_LIST="/etc/apt/sources.list.d/contrib.list"
	echo "deb http://deb.debian.org/debian/ ${VERSION_CODENAME} contrib" >"$SOURCES_LIST"
	apt-get update
	apt-get install -y "linux-headers-$(uname -r)"
	apt-get install -y zfsutils-linux
elif [ "$OS_ID" = "rocky" ]; then
	dnf install -y epel-release
	dnf config-manager --enable epel
	dnf install -y "https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm"
	dnf config-manager --disable zfs
	dnf config-manager --enable zfs-kmod
	dnf install -y zfs
else
	echo "Unsupported OS: $OS_ID"
	exit 1
fi
