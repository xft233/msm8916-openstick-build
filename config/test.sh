#! /bin/bash

apt-get -y update
apt-get install -y binfmt-support qemu-user-static
apt-get install -y debootstrap

mkdir -p output/working rootfs
# prep rootfs image
truncate -s 1024M output/working/rootfs_base.btrfs
mkfs.btrfs output/working/rootfs_base.btrfs
sleep 5
mount -o compress=zstd output/working/rootfs_base.btrfs rootfs

# debootstrap bullseye
mount --bind /proc ./rootfs/proc 
mount --bind /dev ./rootfs/dev # causes device busy
mount --bind /dev/pts ./rootfs/dev/pts
mount --bind /sys ./rootfs/sys
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F" > /proc/sys/fs/binfmt_misc/register
cat /proc/sys/fs/binfmt_misc/register

export DEBIAN_VERSION=testing
debootstrap --arch=arm64 --include openssh-server,nano,wget,initramfs-tools,cron,wpasupplicant,init,dbus,dnsmasq,ca-certificates,gawk $DEBIAN_VERSION rootfs http://deb.debian.org/debian/
cp $(which qemu-aarch64-static) rootfs/usr/bin
cat /proc/sys/fs/binfmt_misc/register

mount | grep binfmt_misc
mount
#
 #chroot rootfs qemu-aarch64-static /bin/bash /debootstrap/debootstrap --second-stage
#rm rootfs/usr/bin/qemu-aarch64-static
