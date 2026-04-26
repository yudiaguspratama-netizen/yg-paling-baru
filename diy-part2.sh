#!/bin/bash

# 1. Mengubah IP LAN default
sed -i 's/192.168.1.1/2.2.2.1/g' package/base-files/files/bin/config_generate

# 2. Mengubah SSID Wifi
# Perintah ini akan mencari semua kata 'ImmortalWrt' atau 'OpenWrt' dan menggantinya
sed -i 's/ImmortalWrt/yudiaguspratama/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i 's/OpenWrt/yudiaguspratama/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 3. Mengaktifkan WiFi secara default
sed -i 's/disabled=1/disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 4. Set Timezone ke Jakarta (WIB) agar SQM/NFT-QOS berjalan sesuai jadwal jika ada
sed -i "s/'UTC'/'WIB-7'/g" package/base-files/files/bin/config_generate
sed -i "s/'UTC'/'Asia\/Jakarta'/g" package/base-files/files/bin/config_generate
