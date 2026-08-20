#! /bin/bash
set -ex
rm -rf /output/*; mkdir -p /output/working

# override kernel config
cp /config/kernel_config /linux/.config

# compile
cd /linux
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
make olddefconfig
make -j$(nproc)

# package kernel => .deb
# need libdw-dev
apt-get install -y libdw-dev
fakeroot make bindeb-pkg

# copy to working
cp /linux/arch/arm64/boot/Image.gz /output/working
cp /linux/arch/arm64/boot/dts/qcom/msm8916-thwc-ufi001c.dtb /output/working
cp /*.deb /output/working
