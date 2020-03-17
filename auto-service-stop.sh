#!/bin/bash

# stop dlna server
sudo service minidlna stop
echo "Stop dlna server"

# stop samba server
sudo service smbd stop
echo "Stop samba server"

# stop torrent server
TORRENT=$(ps -ef | grep qbit | grep nox | awk '{print $2}')
sudo kill -9 $TORRENT
echo "Stop torrent server"

# umount hdd
sudo fuser -ku /home/Share
sudo umount /home/Share
echo "Umount hdd"
