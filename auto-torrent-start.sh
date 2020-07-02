#!/bin/bash

# Check mounted share
MO=`mount | grep Share`

if [ ! -z "$MO" ]; then
	echo "Share is already mounted."
	exit 1
fi

# Find extra hdd
ARR_HDD_SIZE="3.7T 931.5G"
HDD=

for size in $ARR_HDD_SIZE; do
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

# Start minidlna
CMD=`systemctl is-enabled minidlna 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service minidlna start
fi

# Start qbittorrent
CMD=`ls /usr/bin/qbittorrent-nox 2>&1 | grep "No such"`
if [ -z "$CMD" ]; then
	sudo su - thor -c "qbittorrent-nox &"
fi

# Start apache2
CMD=`systemctl is-enabled apache2 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service apache2 start
fi

# Start netatalk afp
CMD=`systemctl is-enabled netatalk 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service netatalk start
fi
