FROM debian:bookworm

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update

########################
## DEPS

# set timezone otherwise we end up stuck in a menu
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
# deps as provided in https://www.kancloud.cn/handsomehacker/openstick/2637565
RUN apt-get install -y binfmt-support qemu-user-static gcc-aarch64-linux-gnu fakeroot android-sdk-libsparse-utils mkbootimg bison
# deps as provided at https://github.com/bkleiner/debian-firecracker
RUN apt-get install -y debootstrap build-essential fakeroot bc kmod cpio flex cpio libncurses5-dev libelf-dev libssl-dev
# deps missing from above
RUN apt-get install -y btrfs-progs build-essential git flex gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libssl-dev rsync

########################
## KERNEL

RUN git clone https://github.com/msm8916-mainline/linux --depth=1 && cd ./linux

########################

VOLUME [ "/config", "/output", "/rootfs" ]
