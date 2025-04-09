#! /bin/bash
set -ex

mv /output/working/rootfs_base.btrfs ./output/rootfs.btrfs
mount -o compress=zstd /output/rootfs.btrfs ./rootfs


########################
# provision prep

mount --bind / /rootfs/mnt

mount --bind /proc /rootfs/proc 
mount --bind /dev /rootfs/dev # causes device busy
mount --bind /dev/pts /rootfs/dev/pts
mount --bind /sys /rootfs/sys

mkdir -p /rootfs/config
mkdir -p /rootfs/output
mount --bind /config /rootfs/config
mount --bind /output /rootfs/output
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F" > /proc/sys/fs/binfmt_misc/register
cp $(which qemu-aarch64-static) /rootfs/usr/bin
chroot /rootfs /bin/bash /config/chroot-system-setup.sh
rm /rootfs/usr/bin/qemu-aarch64-static

########################
# boot.img

cat /output/working/Image.gz /output/working/msm8916-thwc-ufi001c.dtb > /output/working/kernel-dtb

mkbootimg \
    --base 0x80000000\
    --kernel_offset 0x00080000\
    --ramdisk_offset 0x02000000\
    --tags_offset 0x01e00000\
    --pagesize 2048\
    --second_offset 0x00f00000\
    --ramdisk /rootfs/boot/initrd.img*\
    --cmdline "earlycon root=PARTUUID=a7ab80e8-e9d1-e8cd-f157-93f69b1d141e rootflags=compress=zstd,defaults,lazytime console=ttyMSM0,115200 no_framebuffer=true rw"\
    --kernel /output/working/kernel-dtb\
    -o /output/boot.img

########################

sync

umount /rootfs/dev/pts
umount /rootfs/output
umount /rootfs/config
rmdir /rootfs/output
rmdir /rootfs/config
umount -f /rootfs/* || true
umount -f /rootfs || true

## below seems to fail but image still works?

# losetup -d /dev/loop99 || true
# mknod -m 660 /dev/loop99 b 7 11 || true
# losetup -P /dev/loop99 /output/rootfs.ext4
# fsck -pf /dev/loop99 || true
# echo y| tune2fs -f -U a7ab80e8-e9d1-e8cd-f157-93f69b1d141e /dev/loop99 || true
# losetup -d /dev/loop99 || true

img2simg /output/rootfs.btrfs /output/rootfs.img

##
ls -la /output
