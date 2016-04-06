#bin/bash

## check the user id
if ! [ -n "$1" ] ; then
	echo "set user id"
	exit
fi

## umount odroid samba
CMD=$(sudo mount | grep odroid)
if [ -n "$CMD" ] ; then
	echo "Un Mount odroid"
	sudo umount /mnt/odroid
fi

echo "set user password:"
read PWD
sudo mount -t cifs -o user=$1,password=$PWD //192.168.0.10/Share /mnt/odroid
echo "Mount odroid"
