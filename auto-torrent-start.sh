#!/bin/bash

# Find 3.7T hdd
HDD=$(sudo fdisk -l | grep " 3.7T" | awk '{print $1}')

# Connect hdd
sudo mount $HDD /home/Share
mount | grep "$HDD"

# qbit torrent start
sudo su - thor -c "qbittorrent-nox &"

# mindlna reload
sudo service minidlna force-reload
