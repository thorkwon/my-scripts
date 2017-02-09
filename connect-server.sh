#bin/bash

## flag
flag=0

## umount server samba
CMD=$(sudo mount | grep server)
if [ -n "$CMD" ] ; then
	echo "un mount server"
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

echo "set user password:"
read PWD
sudo mount -t cifs -o user=$1,password=$PWD //192.168.0.10/Share /mnt/server
echo "mount server"
