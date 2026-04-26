#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. Tambahkan feed src-git untuk aplikasi tambahan (Opsional)
# Ini berguna jika Anda ingin paket yang lebih lengkap dari komunitas
echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default

# 2. Pastikan feed bawaan ImmortalWrt aktif
# Biasanya sudah otomatis, tapi baris ini memastikan tidak ada yang terkomentar
sed -i 's/^#\(src-git custom\)/\1/' feeds.conf.default
