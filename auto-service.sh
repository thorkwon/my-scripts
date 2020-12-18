#!/usr/bin/env bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

function help()
{
	echo "Usage: $0 command"
	echo "Command:"
	echo "  start     service start"
	echo "  stop      service stop"
	echo "  restart   service restart"
	echo "  status    service status"
	exit 1
}

function get_uuid()
{
	local UUID=""
	if [ -f ${SCRIPTPATH}/$1 ]; then
		UUID=$(cat ${SCRIPTPATH}/$1)
		echo "$UUID"
	fi
}

function mount_hdd()
{
	# Check mounted share
	local MO=`mount | grep Share`

	if [ ! -z "$MO" ]; then
		echo "Share is already mounted."
		exit 1
	fi

	# Find extra hdd
	local NAME_HDD="hdd1.txt"
	local UUID=$(get_uuid $NAME_HDD)
	if [ -z "$UUID" ]; then
		echo "Cannot access '$NAME_HDD': No such file"
		echo "You have to create a file '$NAME_HDD' in the '$SCRIPTPATH'"
		echo "Enter the hdd uuid in the '$NAME_HDD' file."
		exit 1
	fi

	local HDD=$(lsblk -lf | grep $UUID | awk '{print $1}')
	if [ -z "$HDD" ]; then
		echo "Not found extra HDD"
		exit 1
	fi

	HDD="/dev/$HDD"
	echo "Found extra Hdd [$HDD]"

	# Connect extra hdd
	sudo mount $HDD /home/Share
	mount | grep "$HDD"
	sync
	sleep 1
}

function umount_hdd()
{
	# umount hdd
	sudo fuser -ku /home/Share
	sudo umount /home/Share && echo "Umount hdd"
}

function start_service()
{
	local LIST_SERVICE=($1)

	for ser in ${LIST_SERVICE[@]}; do
		local CMD=`systemctl is-enabled ${ser} 2>&1 | grep Failed`
		if [ -z "$CMD" ]; then
			sudo systemctl start ${ser}
			echo "Start ${ser}"
		fi
	done
}

function stop_service()
{
	local LIST_SERVICE=($1)

	local idx=$(( ${#LIST_SERVICE[@]} -1 ))
	while [[ -1 -lt idx ]]; do
		local ser=${LIST_SERVICE[$idx]}
		local CMD=`systemctl is-enabled ${ser} 2>&1 | grep Failed`
		if [ -z "$CMD" ]; then
			sudo systemctl stop ${ser}
			echo "Stop ${ser}"
		fi
		((idx--))
	done
}

function status_service()
{
	local LIST_SERVICE=($1)

	for ser in ${LIST_SERVICE[@]}; do
		local CMD=`systemctl is-enabled ${ser} 2>&1 | grep Failed`
		if [ -z "$CMD" ]; then
			systemctl status ${ser} | grep -B8 Active:
			echo ""
		fi
	done
}

if ! [ -f "${SCRIPTPATH}/service.list" ]; then
	echo "Cannot access 'service.list': No such file"
	echo "You have to create a file 'service.list' in the '$SCRIPTPATH'"
	exit 1
fi

LIST_SERVICE="`cat ${SCRIPTPATH}/service.list`"

if [ $# -eq 0 ]; then
	help
fi

case $1 in
	start)
		mount_hdd
		start_service "${LIST_SERVICE[@]}"
		;;
	stop)
		stop_service "${LIST_SERVICE[@]}"
		umount_hdd
		;;
	restart)
		stop_service "${LIST_SERVICE[@]}"
		umount_hdd
		mount_hdd
		start_service "${LIST_SERVICE[@]}"
		;;
	status)
		status_service "${LIST_SERVICE[@]}"
		;;
	*)
		help
		;;
esac
