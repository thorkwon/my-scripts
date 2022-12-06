#!/usr/bin/env bash

OS=$(uname)
if ! [ "$OS" = "Darwin" ]; then
	exit 1
fi

usage()
{
	echo "Usage: $0 <REQUIRED> [OPTIONS]"
	echo ""
	echo "Required:"
	echo "    -s, --server        : Server domain or address"
	echo "    -u, --user          : User name"
	echo ""
	echo "Options:"
	echo "    -d, --disconnect    : Disconnect server"
	echo "    -h, --help"
	echo ""
	echo "e.g."
	echo "    $0 -s server-domain -u user-name    # Connect server"
	echo "    $0 -s server-domain -d              # Disconnect server"
	exit 1
}

umount_smb()
{
	CMD=$(mount | grep "$MOUNT_DIR")
	if [ -n "$CMD" ] ; then
		CMD=$(umount $MOUNT_PATH 2>&1)
		if [ -n "$CMD" ]; then
			echo -e "Resource busy\nfuser -u: $MOUNT_PATH"
			fuser -u $MOUNT_PATH
			exit 1
		fi
		echo "Umount server[$SERVER]"
		rmdir $MOUNT_PATH
	fi
}

mount_smb()
{
	# check the server is online
	nc -vz -G1 ${SERVER} 445
	if [ $? -ne 0 ]; then
		echo "Please make sure the server is online."
		exit 1
	fi

	# check mount path
	if ! [ -d $MOUNT_PATH ]; then
		mkdir -p $MOUNT_PATH
	fi

	# You have to add hostname of server into '/etc/hosts'
	mount -t smbfs smb://${ID}:${PW}@${SERVER}/Share ${MOUNT_PATH}
	local CMD=$(mount | grep $MOUNT_DIR)
	if [ -n "$CMD" ] ; then
		echo "Mount server[$SERVER]	user[$ID]"
	fi

	echo "Mount path: ${MOUNT_PATH}"
}

check_optarg_error()
{
	if [[ "$1" == "-"* || "$1" = "" ]]; then
		usage
	fi
}

OPT_ONLY_DISCONNECT=0
SERVER=""
ID=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	-s | --server)
		check_optarg_error $2
		SERVER=$2
		shift 2
	;;
	-u | --user)
		check_optarg_error $2
		ID=$2
		shift 2
	;;
	-d | --disconnect)
		OPT_ONLY_DISCONNECT=1
		shift
	;;
	-h | --help)
		usage
	;;
	*)
		usage
	;;
	esac
done

if [ "$SERVER" = "" ]; then
	usage
fi

MOUNT_DIR="remote_${SERVER}"
MOUNT_PATH="${HOME}/mnt/${MOUNT_DIR}"

if [ $OPT_ONLY_DISCONNECT -eq 1 ]; then
	umount_smb
	exit 0
fi

if [ "$ID" = "" ]; then
	usage
fi

umount_smb

echo "user: $ID"
echo -n "password:"
read -s PW
echo ""

mount_smb
