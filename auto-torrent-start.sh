#!/bin/bash

# Check mounted share
MO=`mount | grep Share`

if [ ! -z "$MO" ]; then
	echo "Share is already mounted."
	exit 1
fi

# Find extra hdd
ARR_HDD_SIZE=(" 3.7T" " 931.5G")
HDD=

for size in ${ARR_HDD_SIZE[@]}; do
	HDD=`sudo fdisk -l | grep $size | awk '{print $1}'`
	if [ ! -z "$HDD" ]; then
		break
	fi
done

if [ -z "$HDD" ]; then
	exit 1
fi

echo "Found extra Hdd [$HDD]"

# Connect extra hdd
sudo mount $HDD /home/Share
mount | grep "$HDD"
sync
sleep 1

# Restart minidlna
sudo service minidlna restart

# Start qbittorrent
sudo su - thor -c "qbittorrent-nox &"
