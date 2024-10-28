#! /bin/bash

apt-get install -y binfmt-support qemu-user-static
apt-get install -y debootstrap build-essential 

mkdir -p output/working rootfs
# prep rootfs image
truncate -s 1024M output/working/rootfs_base.ext4
mkfs.ext4 output/working/rootfs_base.ext4
sleep 5
mount output/working/rootfs_base.ext4 rootfs

# debootstrap bullseye
export DEBIAN_VERSION=bullseye
debootstrap --foreign --arch=arm64 --include openssh-server,nano,wget,initramfs-tools,cron,wpasupplicant,init,dbus,dnsmasq,ca-certificates,gawk $DEBIAN_VERSION rootfs http://deb.debian.org/debian/
cp $(which qemu-aarch64-static) rootfs/usr/bin
chroot rootfs qemu-aarch64-static /bin/bash /debootstrap/debootstrap --second-stage
#rm rootfs/usr/bin/qemu-aarch64-static
