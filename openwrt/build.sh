#!/usr/bin/env bash
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
git checkout v21.02.2

./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig

make -j $(nproc) defconfig download clean world

