#!/bin/bash

## flag
flag=0

## umount server samba
CMD=$(sudo mount | grep server)
if [ -n "$CMD" ] ; then
	echo "Un mount server"
	sudo fuser -cu /mnt/server/
	sudo umount /mnt/server
	flag=1
fi

## check the user id
if [ $flag = 1 -a -z "$1" ] ; then
	exit 1
elif [ -z "$1" ] ; then
	echo "set user id"
	exit 1
fi

## You have to add hostname of server into '/etc/hosts'
sudo mount -t cifs -o user=$1 //server/Share /mnt/server
CMD=$(sudo mount | grep server)
if [ -n "$CMD" ] ; then
	echo "Mount server	user[$1]"
fi
