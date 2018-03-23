#!/bin/sh
# script ini untuk ubah file named.conf.local

# awal
echo "Domain : "
read domain

echo "IP domain : "
read IP

# Path file 
dir="/home/admin_server/testing.conf"

# write to file
echo "zone	\"$domain\"	{" >> ${dir}
echo "	type master;" >> ${dir}
echo "	file \"forward\";" >> ${dir}
echo "};\n" >> ${dir}

# REVERSE
# split IP by delimiter '.'
IP_seg1=$(echo "$IP" | cut -d "." -f 1)
#IP_seg2=$(echo "$IP" | cut -d "." -f 2)
#IP_seg3=$(echo "$IP" | cut -d "." -f 3)
#IP_seg4=$(echo "$IP" | cut -d "." -f 4)

# gabung string
#combine="$IP_seg4.$IP_seg3.$IP_seg2.$IP_seg1"
#combine="$IP_seg3.$IP_seg2.$IP_seg1"	# jika menggunakan 3 segmen
#combine="$IP_seg2.$IP_seg1"		# jika menggunakan 2 segmen
combine="$IP_seg1"			# jika menggunakan 1 segmen
IP_cut=$combine

# write to file
echo "zone	\"$IP_cut.in-addr.arpa\"	{" >> ${dir}
echo "	type master;" >> ${dir}
echo "	file \"reverse\";" >> ${dir}
echo "};" >> ${dir}
