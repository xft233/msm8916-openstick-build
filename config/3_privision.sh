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

# -----

umount /rootfs || true
mount /output/rootfs.ext4 /rootfs

########################
# boot.img

cat /output/working/Image.gz /output/working/msm8916-handsome-openstick-sp970.dtb > /output/working/kernel-dtb

mkbootimg \
    --base 0x80000000\
    --kernel_offset 0x00080000\
    --ramdisk_offset 0x02000000\
    --tags_offset 0x01e00000\
    --pagesize 2048\
    --second_offset 0x00f00000\
    --ramdisk /rootfs/boot/initrd.img-5.15.0-handsomekernel+\
    --cmdline "earlycon root=PARTUUID=a7ab80e8-e9d1-e8cd-f157-93f69b1d141e console=ttyMSM0,115200 no_framebuffer=true rw"\
    --kernel /output/working/kernel-dtb\
    -o /output/boot.img

########################

sync
sleep 5
umount -f /rootfs/* || true
umount -f /rootfs || true

sleep 5

## below seems to fail but image still works?

 losetup -d /dev/loop99 || true
 mknod -m 660 /dev/loop99 b 7 11 || true
 losetup -P /dev/loop99 /output/rootfs.ext4
 fsck -pf /dev/loop99 || true
 echo y| tune2fs -f -U a7ab80e8-e9d1-e8cd-f157-93f69b1d141e /dev/loop99 || true
 losetup -d /dev/loop99 || true

img2simg /output/rootfs.ext4 /output/rootfs.img

##
ls -la /output


echo "debian-$DEBIAN_VERSION" > /etc/hostname
passwd -d root

apt -y install mobile-tweaks-common network-manager locales sudo systemd-timesyncd curl vim

########################
# KERNEL
dpkg -i /output/working/linux-headers-*.deb
dpkg -i /output/working/linux-image-*.deb

########################
# CONSOLE

mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat <<EOF > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root -o '-p -- \\u' --keep-baud 115200,38400,9600 %I $TERM
EOF

########################
# FIRMWARE

# required wifi/vpu firmware; alternative is bulky: https://packages.debian.org/bullseye/firmware-qcom-soc ... and alternative: https://github.com/HandsomeMod/qcom-firmware
dpkg -i /output/working/linux-firmware-snapdragon_1.3-0ubuntu3_arm64.deb

########################
# ADBD & USB networking
apt -y install adbd

# ADB daemon from https://github.com/hyx0329/openstick-failsafe-guard which was ripped from https://github.com/OpenStick/OpenStick/releases/download/v1/debian.zip, source not sure (alternative?: http://http.us.debian.org/debian/pool/main/a/android-tools/android-tools-adbd_5.1.1.r38-1.1_arm64.deb)
# cp /output/working/openstick-failsafe-guard/bin/adbd-static /usr/bin/adbd && chmod +x /usr/bin/adbd

# gc tool from https://github.com/hyx0329/openstick-failsafe-guard which was ripped from https://github.com/OpenStick/OpenStick/releases/download/v1/debian.zip, source: https://github.com/HandsomeMod/gc
# cp /output/working/openstick-failsafe-guard/bin/gc-static /usr/bin/gc && chmod +x /usr/bin/gc

# service bits from https://github.com/hyx0329/openstick-failsafe-guard
# cp /output/working/openstick-failsafe-guard/openstick-gc-manager/openstick-gc-manager.sh /usr/sbin/ && chmod +x /usr/sbin/openstick-gc-manager.sh
# cp /output/working/openstick-failsafe-guard/openstick-gc-manager/*.service /usr/lib/systemd/system/
# ln -s /usr/lib/systemd/system/adbd.service /etc/systemd/system/multi-user.target.wants/adbd.service
# ln -s /usr/lib/systemd/system/openstick-gc-startup.service /etc/systemd/system/multi-user.target.wants/openstick-gc-startup.service

# service bits from https://salsa.debian.org/Mobian-team/mobile-usb-networking
# cp /output/working/mobile-usb-networking/mobile-usb-gadget /usr/sbin/ && chmod +x /usr/sbin/mobile-usb-gadget
# cp /output/working/mobile-usb-networking/mobile-usb-network-setup /usr/sbin/ && chmod +x /usr/sbin/mobile-usb-network-setup
# cp /output/working/mobile-usb-networking/debian/mobile-usb-networking.mobile-usb-gadget.service /usr/lib/systemd/system/mobile-usb-gadget.service
# cp /output/working/mobile-usb-networking/debian/mobile-usb-networking.mobile-usb-network-setup.service /usr/lib/systemd/system/mobile-usb-network-setup.service
# ln -s /usr/lib/systemd/system/mobile-usb-gadget.service /etc/systemd/system/multi-user.target.wants/mobile-usb-gadget.service
# ln -s /usr/lib/systemd/system/mobile-usb-network-setup.service /etc/systemd/system/multi-user.target.wants/mobile-usb-network-setup.service

# DHCP server dnsmasq:
cat <<EOF >> /etc/dnsmasq.conf
listen-address=192.168.68.1
dhcp-range=192.168.68.10, 192.168.68.254, 12h
EOF

####

df -h /
