#! /bin/bash
set -ex

umount ./rootfs || true
cp ./output/working/rootfs_base.ext4 ./output/rootfs.ext4
mount ./output/rootfs.ext4 ./rootfs


########################
# provision prep

mount --bind / ./rootfs/mnt

mount --bind /proc ./rootfs/proc 
mount --bind /dev ./rootfs/dev # causes device busy
mount --bind /dev/pts ./rootfs/dev/pts
mount --bind /sys ./rootfs/sys

mkdir -p ./rootfs/config
mkdir -p ./rootfs/output
mount --bind ./config ./rootfs/config
mount --bind ./output ./rootfs/output

cp $(which qemu-aarch64-static) ./rootfs/usr/bin
chroot ./rootfs /bin/bash /config/provision.sh
rm ./rootfs/usr/bin/qemu-aarch64-static

sync
sleep 5
umount -f ./rootfs/* || true
umount -f ./rootfs || true

sleep 5
