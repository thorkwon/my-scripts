#bin/bash

## check the user id
if ! [ -n "$1" ] ; then
	echo "set user id"
	exit
fi

## umount server samba
CMD=$(sudo mount | grep server)
if [ -n "$CMD" ] ; then
	echo "un mount server"
	sudo fuser -cu /mnt/server/
	sudo umount /mnt/server
fi

echo "set user password:"
read PWD
sudo mount -t cifs -o user=$1,password=$PWD //192.168.0.10/Share /mnt/server
echo "mount server"
