#!/bin/bash

# connect hdd
sudo mount /dev/sda1 /home/Share
mount | grep sda1

# qbit torrent start
sudo su - khg -c "qbittorrent-nox &"
