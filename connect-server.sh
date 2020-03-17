#!/bin/bash

flag=0

# umount samba server
CMD=`sudo mount | grep server`
if [ -n "$CMD" ] ; then
	echo "Un mount server"
	sudo fuser -ku /mnt/server/
	sudo umount /mnt/server
	flag=1
fi

# check the user id
if [ $flag = 1 -a -z "$1" ]; then
	exit 1
elif [ -z "$1" ]; then
	echo "set user id"
	exit 1
fi

# check the server is online
CMD=`nc -vz -w1 server 139 445 2>&1 | grep succeeded`
if [ -z "$CMD" ]; then
	echo "Please make sure the server is online."
	exit 1
fi

# get uid and gid
U_ID=`id | awk '{print $1}' | awk -F '(' '{print $1}'`
G_ID=`id | awk '{print $2}' | awk -F '(' '{print $1}'`

# You have to add hostname of server into '/etc/hosts'
sudo mount -t cifs -o user=$1,$U_ID,$G_ID //server/Share /mnt/server
CMD=`sudo mount | grep server`
if [ -n "$CMD" ] ; then
	echo "Mount server	user[$1]"
fi
