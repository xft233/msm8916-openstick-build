#! /bin/bash
set -ex

#download extras
pushd ./output/working
# git clone https://salsa.debian.org/Mobian-team/mobile-usb-networking --depth=1 && cd ./mobile-usb-networking && git checkout 056d9215bb38697b9dc59ba256fc6e904ee5923d && cd ..
# git clone https://github.com/hyx0329/openstick-failsafe-guard --depth=1 && cd ./openstick-failsafe-guard && git checkout 07a8cc6e2558411f746a3cf529c7565dc88668ba && cd ..
wget http://ports.ubuntu.com/pool/multiverse/l/linux-firmware-snapdragon/linux-firmware-snapdragon_1.3-0ubuntu3_arm64.deb
popd

# prep rootfs image
truncate -s 1024M ./output/working/rootfs_base.btrfs
mkfs.btrfs ./output/working/rootfs_base.btrfs

mount -o compress=zstd ./output/working/rootfs_base.btrfs ./rootfs

# debootstrap bullseye
export DEBIAN_VERSION=testing
debootstrap --foreign --arch=arm64 --include btrfs-progs,openssh-server,nano,wget,initramfs-tools,cron,wpasupplicant,init,dbus,dnsmasq,ca-certificates,gawk $DEBIAN_VERSION ./rootfs http://deb.debian.org/debian/

mount --bind /proc ./rootfs/proc 
mount --bind /dev ./rootfs/dev # causes device busy
mount --bind /dev/pts ./rootfs/dev/pts
mount --bind /sys ./rootfs/sys
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
sh -c 'echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64:F" > /proc/sys/fs/binfmt_misc/register'

cp $(which qemu-aarch64-static) ./rootfs/usr/bin
chroot ./rootfs /usr/bin/qemu-aarch64-static /bin/sh /debootstrap/debootstrap --second-stage
rm ./rootfs/usr/bin/qemu-aarch64-static

umount ./rootfs/dev/pts
umount ./rootfs/dev
umount ./rootfs/sys
umount ./rootfs/proc
umount ./rootfs
