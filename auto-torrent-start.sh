#!/bin/bash

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

# Connect hdd
sudo mount $HDD /home/Share
mount | grep "$HDD"

# qbit torrent start
sudo su - thor -c "qbittorrent-nox &"

# mindlna reload
sudo service minidlna force-reload
