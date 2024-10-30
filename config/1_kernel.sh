#! /bin/bash
set -ex

rm -rf /output/*; mkdir -p /output/working

# override kernel config
cp /config/msm8916_defconfig /linux/arch/arm64/configs/msm8916_defconfig

# compile
cd /linux
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
make clean
make msm8916_defconfig
cp .config /output/working/
# make menuconfig
