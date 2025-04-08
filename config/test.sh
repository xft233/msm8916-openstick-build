#! /bin/bash

apt-get -y update
apt-get install -y binfmt-support qemu-user-static
apt-get install -y debootstrap

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
cat /proc/sys/fs/binfmt_misc/register
mount --bind /proc ./rootfs/proc 
mount --bind /dev ./rootfs/dev # causes device busy
mount --bind /dev/pts ./rootfs/dev/pts
mount --bind /sys ./rootfs/sys
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
sh -c 'echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64:F" > /proc/sys/fs/binfmt_misc/register'
cat /proc/sys/fs/binfmt_misc/register

chroot rootfs qemu-aarch64-static /bin/bash /debootstrap/debootstrap --second-stage
#rm rootfs/usr/bin/qemu-aarch64-static
