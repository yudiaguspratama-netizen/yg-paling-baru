#!/bin/bash

# 1. Identitas Perangkat
sed -i 's/ADSLR G7/ZTE E8820V2/g' package/base-files/files/bin/config_generate

# 2. Matikan IPv6 secara permanen (Hemat RAM & CPU)
sed -i 's/option disable_ipv6 0/option disable_ipv6 1/g' package/base-files/files/bin/config_generate

# 3. Kunci ukuran Log sistem agar tidak memakan RAM
sed -i 's/log_size/log_size 8/g' package/base-files/files/bin/config_generate

# 4. Injeksi Skrip ke rc.local (Konfigurasi Utama saat Booting)
cat <<EOF > package/base-files/files/etc/rc.local
# --- OPTIMASI GHOST ENGINE ---
# Matikan service yang tidak diperlukan di router kedua
/etc/init.d/log stop
/etc/init.d/log disable
/etc/init.d/cron stop
/etc/init.d/cron disable

# MATIKAN FIREWALL & NAT (Mode Transparan)
# Membuat CPU sangat ringan karena tidak melakukan translasi paket
/etc/init.d/firewall stop
/etc/init.d/firewall disable

# --- KONTROL BANDWIDTH (TC DINAMIS) ---
DEV="br-lan"
TOTAL_SPEED="30mbit"
PER_USER_MIN="2mbit"

# Bersihkan aturan lama
tc qdisc del dev \$DEV root 2>/dev/null

# Jalur Default: Masuk ke Class 100 (Jalur Umum/Limit Ketat)
tc qdisc add dev \$DEV root handle 1: htb default 100

# Pipa Utama (Full Capacity)
tc class add dev \$DEV parent 1: classid 1:1 htb rate \$TOTAL_SPEED ceil \$TOTAL_SPEED

# A. KELAS UMUM (Untuk Tamu / IP Tak Terdaftar)
# Limit 2Mbps agar bandwidth utama Anda tetap aman
tc class add dev \$DEV parent 1:1 classid 1:100 htb rate 1mbit ceil 2mbit prio 7

# B. JALUR VIP (IP .51 - .60)
# Prioritas tertinggi, Bypass limit (Full Speed)
tc class add dev \$DEV parent 1:1 classid 1:30 htb rate \$TOTAL_SPEED ceil \$TOTAL_SPEED prio 0
for i in \$(seq 51 60); do
    tc filter add dev \$DEV protocol ip parent 1:0 prio 1 u32 match ip dst 192.168.1.\$i flowid 1:30
done

# C. JALUR BIASA (IP .2 - .50)
# Pembagian dinamis: adil saat ramai, kencang saat sepi
for i in \$(seq 2 50); do
    tc class add dev \$DEV parent 1:1 classid 1:\$i htb rate \$PER_USER_MIN ceil \$TOTAL_SPEED prio 5
    tc filter add dev \$DEV protocol ip parent 1:0 prio 2 u32 match ip dst 192.168.1.\$i flowid 1:\$i
done

# --- OPTIMASI LANJUTAN UNTUK 100 USER ---
# Tingkatkan kapasitas tabel koneksi kernel
echo 16384 > /proc/sys/net/netfilter/nf_conntrack_max
# Bersihkan koneksi basi lebih cepat agar RAM tidak penuh
echo 600 > /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established

# Pembersihan RAM akhir
sync && echo 3 > /proc/sys/vm/drop_caches

exit 0
EOF
