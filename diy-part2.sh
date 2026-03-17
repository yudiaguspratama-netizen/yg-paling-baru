#!/bin/bash

# 1. Identitas & IP LAN (Sesuaikan IP jika perlu)
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/GhostEngine/g' package/base-files/files/bin/config_generate

# 2. Matikan IPv6
sed -i 's/option disable_ipv6 0/option disable_ipv6 1/g' package/base-files/files/bin/config_generate

# 3. Injeksi Konfigurasi ke rc.local
cat <<EOF > package/base-files/files/etc/rc.local
# Matikan service berat
/etc/init.d/firewall stop
/etc/init.d/firewall disable
/etc/init.d/log stop
/etc/init.d/log disable

# --- KONTROL BANDWIDTH (TC DINAMIS) ---
DEV="br-lan"
TOTAL_SPEED="30mbit"
PER_USER_MIN="2mbit"

tc qdisc del dev \$DEV root 2>/dev/null
tc qdisc add dev \$DEV root handle 1: htb default 100
tc class add dev \$DEV parent 1: classid 1:1 htb rate \$TOTAL_SPEED ceil \$TOTAL_SPEED

# Jalur Umum (Limit 2mbps)
tc class add dev \$DEV parent 1:1 classid 1:100 htb rate 1mbit ceil 2mbit prio 7

# Jalur VIP (.51 - .60)
tc class add dev \$DEV parent 1:1 classid 1:30 htb rate \$TOTAL_SPEED ceil \$TOTAL_SPEED prio 0
for i in \$(seq 51 60); do
    tc filter add dev \$DEV protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.1.\$i flowid 1:30
done

# Jalur Biasa (.2 - .50)
for i in \$(seq 2 50); do
    tc class add dev \$DEV parent 1:1 classid 1:\$i htb rate \$PER_USER_MIN ceil \$TOTAL_SPEED prio 5
    tc filter add dev \$DEV protocol ip parent 1:0 prio 2 u32 match ip dst 192.168.1.\$i flowid 1:\$i
done

# Optimasi Kernel untuk 100 User
echo 16384 > /proc/sys/net/netfilter/nf_conntrack_max
echo 600 > /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established

sync && echo 3 > /proc/sys/vm/drop_caches
exit 0
EOF
