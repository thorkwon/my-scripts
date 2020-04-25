#!/bin/bash

# stop apache2
CMD=`systemctl is-enabled apache2 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service apache2 stop
	echo "Stop apache2 server"
fi

# stop dlna server
CMD=`systemctl is-enabled minidlna 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service minidlna stop
	echo "Stop dlna server"
fi

# stop samba server
CMD=`systemctl is-enabled smbd 2>&1 | grep Failed`
if [ -z "$CMD" ]; then
	sudo service smbd stop
	echo "Stop samba server"
fi

# stop torrent server
TORRENT=$(ps -ef | grep qbit | grep nox | awk '{print $2}')
if [ -n "$TORRENT" ]; then
	sudo kill -9 $TORRENT
	echo "Stop torrent server"
fi

# umount hdd
sudo fuser -ku /home/Share
sudo umount /home/Share
echo "Umount hdd"
