#!/bin/bash
#
domain="mrxz.net"
IP="192.168.2.1"

# DNS static
DNS_resolv_conf=/etc/resolv.conf
sudo sed -i '/^nameserver/d' ${DNS_resolv_conf}
sudo echo "nameserver $IP" >> ${DNS_resolv_conf}
sudo echo "nameserver 8.8.8.8" >> ${DNS_resolv_conf}
sudo echo "nameserver 8.8.4.4" >> ${DNS_resolv_conf}
sudo echo "search $domain" >> ${DNS_resolv_conf}
sudo chattr -i /etc/resolv.conf

# directory
dir_forward=/var/cache/bind/forward
dir_reverse=/var/cache/bind/reverse

# FORWARD
sudo cp /etc/bind/db.local ${dir_forward}
sudo sed -i '/^$/d' ${dir_forward}
sudo sed -i '/^;/d' ${dir_forward}
sudo sed -i "s/localhost/$domain/g" ${dir_forward}
sudo sed -i "s/127.0.0.1/$IP/g" ${dir_forward}
sudo sed -i '$d' ${dir_forward}
sudo echo -e "www\tIN\tA\t$IP" >> ${dir_forward}
sudo echo -e "ftp\tIN\tA\t$IP" >> ${dir_forward}
sudo echo -e "mail\tIN\tA\t$IP" >> ${dir_forward}

# REVERSE
# split IP by delimiter '.'
IP_seg1=$(echo "$IP" | cut -d "." -f 1)
IP_seg2=$(echo "$IP" | cut -d "." -f 2)
IP_seg3=$(echo "$IP" | cut -d "." -f 3)
IP_seg4=$(echo "$IP" | cut -d "." -f 4)

# jika di file named.conf.local pada bagian reverse menggunakan 1 segmen 
# maka pada file reverse akan menggunakan 3 segmen
# gabung string
combine="$IP_seg4.$IP_seg3.$IP_seg2"   	# jika menggunakan 3 segmen
#combine="$IP_seg4.$IP_seg3"            # jika menggunakan 2 segmen
#combine="$IP_seg4"                     # jika menggunakan 1 segmen
IP_cut=$combine

sudo cp ${dir_forward} ${dir_reverse}
sudo sed -i '/^www/d' ${dir_reverse}
sudo sed -i '/^ftp/d' ${dir_reverse}
sudo sed -i '/^mail/d' ${dir_reverse}
sudo sed -i '/^@\tIN\tA/d' ${dir_reverse}
sudo echo -e "$IP_cut\tIN\tPTR\t$domain" >> ${dir_reverse}
