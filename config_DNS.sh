#!/bin/bash
# Script ini untuk setup DNS static server ubuntu

hostname=$( cat /etc/hostname)
IP_hostname="$(getent hosts $hostname)"
domain=""
newhost=""

# split to IP of hostname. use awk
IP=$( echo "$IP_hostname" | awk '{print $1}' )

# store
old_hostname=${hostname}
old_IP=${IP}

# show IP of hostname
echo "Existing hostname	: $hostname"
echo "Existing IP		: $IP"

# ask new hostname
read -p "Ubah hostname (y/n) : " answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	echo "New hostaname : "
	read newhost
	sudo sed -i "s/$old_hostname/$newhost/g" /etc/hostname
	hostname=${newhost}
esac

#ask new IP
read -p "Ubah IP hostname (y/n) : " answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	echo "New IP : "
	read newIP
	#sudo sed -i "s/$IP/$newIP/g" /etc/hosts
	IP=${newIP}
esac

#case $newhost in
#  (*[![:blank:]]*) 
#  	hostname=${newhost};;
#esac

# ask new domain
read -p "Ubah domain (y/n) : " answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	echo "New domain : "
	read newdomain
	domain=${newdomain}
esac

del_num=$(sed -n  "\|${old_IP}\s\+${old_hostname}|=" /etc/hosts)
#echo $del_num
sed -i "${del_num}d" /etc/hosts
sed -i "${del_num}i ${IP}\t${hostname}.${domain}\t${hostname}" /etc/hosts

#sudo sed -i "s/$hostname/$newhost/g" /etc/hosts

##############################
# script ini untuk ubah file named.conf.local

# Path file 
dir="/etc/bind/named.conf.local"

# hapus baris yang tidak diawali //
sudo sed -i '/\/\//!d' ${dir}

# write to file
echo "zone	\"$domain\"	{" >> ${dir}
echo "	type master;" >> ${dir}
echo "	file \"forward\";" >> ${dir}
echo "};\n" >> ${dir}

# REVERSE
# Jika pada reverse menggunakan 1 segmen -> uncomment IP_seg1
# Jika pada reverse menggunakan 2 segmen -> uncomment IP_seg1 dan IP_seg2
# Jika pada reverse menggunakan 3 segmen -> uncomment IP_seg1, IP_seg2 dan IP_seg3
# ket : uncomment -> hapus tanda pagar di depan variabel tersebut

# split IP by delimiter '.'
IP_seg1=$(echo "$IP" | cut -d "." -f 1)
IP_seg2=$(echo "$IP" | cut -d "." -f 2)
#IP_seg3=$(echo "$IP" | cut -d "." -f 3)
#IP_seg4=$(echo "$IP" | cut -d "." -f 4)

# gabung string
#combine="$IP_seg4.$IP_seg3.$IP_seg2.$IP_seg1"
#combine="$IP_seg3.$IP_seg2.$IP_seg1"	# jika menggunakan 3 segmen
combine="$IP_seg2.$IP_seg1"		# jika menggunakan 2 segmen
#combine="$IP_seg1"			# jika menggunakan 1 segmen
IP_cut=$combine

# write to file
echo "zone	\"$IP_cut.in-addr.arpa\"	{" >> ${dir}
echo "	type master;" >> ${dir}
echo "	file \"reverse\";" >> ${dir}
echo "};" >> ${dir}

###############################

# DNS static
DNS_resolv_conf=/etc/resolv.conf
sudo sed -i '/^nameserver/d' ${DNS_resolv_conf}
sudo sed -i '/^search/d' ${DNS_resolv_conf}
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

# PERHATIKAN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# jika di file named.conf.local pada bagian REVERSE menggunakan 1 segmen 
# maka pada file reverse akan menggunakan 3 segmen
# jika di file named.conf.local pada bagian REVERSE menggunakan 2 segmen 
# maka pada file reverse akan menggunakan 2 segmen
# jika di file named.conf.local pada bagian REVERSE menggunakan 3 segmen 
# maka pada file reverse akan menggunakan 1 segmen
# Untuk penerapannya silahkan hapus tanda pagar di bagian depan variabel combine di bawah ini 
# sesuai dengan segmen yang digunakan

# contoh : di file named.conf.local pada bagian rever menggunakan 1 segmen
# IP : server = 192.168.2.1
#
# /etc/bind/named.conf.local
# zone    "192.in-addr.arpa"      {
#        type master;
#        file "reverse";
# };
# 
# maka setup yang diperlukan: 
# uncomment ==> combine="$IP_seg4.$IP_seg3.$IP_seg2"
# combine yang lainnya di comment saja
# =======================================================
# JIKA MENGGUNAKAN 2 SEGMEN
# zone    "168.192.in-addr.arpa"      {
#        type master;
#        file "reverse";
# };
# 
# maka setup yang diperlukan: 
# uncomment ==> combine="$IP_seg4.$IP_seg3"
# combine yang lainnya di comment saja

# gabung string
#combine="$IP_seg4.$IP_seg3.$IP_seg2"   	# jika menggunakan 3 segmen
combine="$IP_seg4.$IP_seg3"            # jika menggunakan 2 segmen
#combine="$IP_seg4"                     # jika menggunakan 1 segmen
IP_cut=$combine

sudo cp ${dir_forward} ${dir_reverse}
sudo sed -i '/^www/d' ${dir_reverse}
sudo sed -i '/^ftp/d' ${dir_reverse}
sudo sed -i '/^mail/d' ${dir_reverse}
sudo sed -i '/^@\tIN\tA/d' ${dir_reverse}
sudo echo -e "$IP_cut\tIN\tPTR\t$domain." >> ${dir_reverse}
sudo service bind9 restart

# ask to reboot
echo "Need reboot!!"
read  -p "Reboot now??? (y/n)" answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	sudo reboot
esac

