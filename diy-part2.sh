#!/bin/bash

# 1. Identitas Perangkat
sed -i 's/ADSLR G7/ZTE E8820V2/g' package/base-files/files/bin/config_generate

# 2. Matikan IPv6 secara permanen
sed -i 's/option disable_ipv6 0/option disable_ipv6 1/g' package/base-files/files/bin/config_generate

# 3. Kunci ukuran Log ke 8KB agar tidak memakan RAM
sed -i 's/log_size/log_size 8/g' package/base-files/files/bin/config_generate

# 4. Matikan Service Logging dan Cron secara paksa saat startup
# Ini membuat RAM tetap kosong dari proses background yang tidak perlu
cat <<EOF > package/base-files/files/etc/rc.local
# Hentikan semua proses logging
/etc/init.d/log stop
/etc/init.d/log disable
/etc/init.d/cron stop
/etc/init.d/cron disable

# Trik Tambahan: Bebaskan cache RAM setiap boot
sync && echo 3 > /proc/sys/vm/drop_caches

exit 0
EOF
