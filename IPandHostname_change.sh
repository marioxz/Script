#!/bin/bash
# Read old hostname & IP
hostname=$( cat /etc/hostname)
IP_hostname="$(getent hosts $hostname)"

# split to IP of hostname. use awk
IP=$( echo "$IP_hostname" | awk '{print $1}' )

# show IP of hostname
echo "Existing hostname	: $hostname"
echo "Existing IP		: $IP"

# ask new hostname
read -p "Ubah hostname (y/n) : " answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	echo "New hostaname : "
	read newhost
	sudo sed -i "s/$hostname/$newhost/g" /etc/hosts
	sudo sed -i "s/$hostname/$newhost/g" /etc/hostname
esac

#ask new IP
read -p "Ubah IP hostname (y/n) : " answer
case "${answer}" in
     [yY][yY][eE][sS]|[yY])
	echo "New IP : "
	read newIP
	sudo sed -i "s/$IP/$newIP/g" /etc/hosts
esac



