#!/usr/bin/env bash

OS=`uname`
if ! [ "$OS" = "Darwin" ]; then
	exit 0
fi

MOUNT_DIR="remote_afp"
MOUNT_PATH="${HOME}/mnt/${MOUNT_DIR}"
FLAG=0

# umount afp server
CMD=`mount | grep $MOUNT_DIR`
if [ -n "$CMD" ] ; then
	CMD=`umount $MOUNT_PATH 2>&1`
	if [ -n "$CMD" ]; then
		echo -e "Resource busy\nfuser -u: $MOUNT_PATH"
		fuser -u $MOUNT_PATH
		exit 1
	fi
	echo "Un mount afp server"
	FLAG=1
fi

# check the afp server
if [ $FLAG -eq 1 -a $# -eq 0 ]; then
	exit 0
elif ! [ $# -eq 2 ]; then
	echo "Usage: $0 <server-name> <user-name>"
	exit 1
fi
SERVER=$1
ID=$2

echo "user: $ID"
echo -n "password:"
read -s PW
echo ""

# check the server is online
CMD=`nc -vz -w1 $SERVER 548 2>&1 | grep succeeded`
if [ -z "$CMD" ]; then
	echo "Please make sure the server is online."
	exit 1
fi

# check mount path
if ! [ -d $MOUNT_PATH ]; then
	mkdir -p $MOUNT_PATH
fi

# You have to add hostname of server into '/etc/hosts'
mount -t afp afp://${ID}:${PW}@${SERVER}/Share ${MOUNT_PATH}
CMD=`mount | grep $MOUNT_DIR`
if [ -n "$CMD" ] ; then
	echo "Mount afp server	user[$ID]"
fi
