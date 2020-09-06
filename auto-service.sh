#!/bin/bash

function help()
{
	echo "Usage: $0 command"
	echo "Command:"
	echo "  start     service restart"
	echo "  stop      service stop"
	echo "  status    service status"
	exit 1
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
	local ARR_HDD_SIZE="3.7T 931.5G"
	local HDD=

	for size in $ARR_HDD_SIZE; do
		HDD=`sudo fdisk -l | grep $size | awk '{print $1}'`
		if [ ! -z "$HDD" ]; then
			break
		fi
	done

	if [ -z "$HDD" ]; then
		exit 1
	fi

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
	sudo umount /home/Share
	echo "Umount hdd"
}

function start_service()
{
	local LIST_SERVICE=($1)

	for ser in ${LIST_SERVICE[@]}; do
		local CMD=`systemctl is-enabled ${ser} 2>&1 | grep Failed`
		if [ -z "$CMD" ]; then
			sudo systemctl restart ${ser}
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
			echo "${ser}.service"
			systemctl status ${ser} | grep Active
			echo ""
		fi
	done
}

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
if ! [ -f "${SCRIPTPATH}/service.list" ]; then
	echo "Cannot access 'service.list': No such file"
	echo "You have to create a file 'service.list' in the '$SCRIPTPATH'"
	exit 1
fi

LIST_SERVICE="`cat ${SCRIPTPATH}/service.list`"

if [ $# == 0 ]; then
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
	status)
		status_service "${LIST_SERVICE[@]}"
		;;
	*)
		help
		;;
esac
