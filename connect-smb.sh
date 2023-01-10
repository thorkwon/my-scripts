#!/usr/bin/env bash

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_RESET=$(tput sgr0)

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
	echo "    -p, --path          : Samba path name"
	echo "    -h, --help"
	echo ""
	echo "e.g."
	echo "    $0 -s server -u user                # Connect server"
	echo "    $0 -s server -u user -p path-name   # Connect server"
	echo "    $0 -s server -d                     # Disconnect server"
	echo "    $0 -s server -d -p path-name        # Disconnect server"
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
			echo -e "Umount\t[${COLOR_RED}Fail${COLOR_RESET}]"
			exit 1
		fi
		echo -e "Umount\t[${COLOR_GREEN}Done${COLOR_RESET}]"
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
	mount -t smbfs smb://${ID}:${PW}@${SERVER}/${SMB_PATH} ${MOUNT_PATH}
	local CMD=$(mount | grep $MOUNT_DIR)
	if [ -n "$CMD" ] ; then
		echo "Mount smb[$SERVER/${SMB_PATH}]	user[$ID]"
		echo "Mount path: ${MOUNT_PATH}"
		echo -e "Mount\t[${COLOR_GREEN}Done${COLOR_RESET}]"
	else
		rmdir ${MOUNT_PATH}
		echo -e "Mount\t[${COLOR_RED}Fail${COLOR_RESET}]"
	fi

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
SMB_PATH="Share"

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
	-p | --path)
		check_optarg_error $2
		SMB_PATH=$2
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

MOUNT_DIR="remote_${SERVER}_${SMB_PATH}"
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
