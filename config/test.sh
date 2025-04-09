#! /bin/bash

apt-get -y update
apt-get install -y binfmt-support qemu-user-static
apt-get install -y debootstrap

mkdir -p output/working rootfs
# prep rootfs image
pushd /output/working
# git clone https://salsa.debian.org/Mobian-team/mobile-usb-networking --depth=1 && cd ./mobile-usb-networking && git checkout 056d9215bb38697b9dc59ba256fc6e904ee5923d && cd ..
# git clone https://github.com/hyx0329/openstick-failsafe-guard --depth=1 && cd ./openstick-failsafe-guard && git checkout 07a8cc6e2558411f746a3cf529c7565dc88668ba && cd ..
wget http://ports.ubuntu.com/pool/multiverse/l/linux-firmware-snapdragon/linux-firmware-snapdragon_1.3-0ubuntu3_arm64.deb
popd
truncate -s 1024M output/working/rootfs_base.btrfs
mkfs.btrfs output/working/rootfs_base.btrfs
sleep 5
mount -o compress=zstd /output/working/rootfs_base.btrfs rootfs

# debootstrap bullseye
export DEBIAN_VERSION=testing
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
debootstrap --arch=arm64 --include apt-utils,dialog,btrfs-progs,openssh-server,nano,wget,initramfs-tools,cron,wpasupplicant,init,dbus,dnsmasq,ca-certificates,gawk $DEBIAN_VERSION /rootfs http://deb.debian.org/debian/

umount /proc/sys/fs/binfmt_misc
umount /rootfs
