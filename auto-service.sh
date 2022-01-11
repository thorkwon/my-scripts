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

	# Find extra hdd1
	local NAME_HDD1="hdd1.txt"
	local UUID1=$(get_uuid $NAME_HDD1)
	if [ -z "$UUID1" ]; then
		echo "Cannot access '$NAME_HDD1': No such file"
		echo "You have to create a file '$NAME_HDD1' in the '$SCRIPTPATH'"
		echo "Enter the hdd uuid in the '$NAME_HDD1' file."
		exit 1
	fi

	local HDD1=$(lsblk -lf | grep $UUID1 | awk '{print $1}')
	if [ -z "$HDD1" ]; then
		echo "Not found extra HDD"
		exit 1
	fi

	HDD1="/dev/$HDD1"
	echo "Found extra Hdd [$HDD1]"

	# Find extra hdd2
	local NAME_HDD2="hdd2.txt"
	local UUID2=$(get_uuid $NAME_HDD2)
	local HDD2=""
	if [ -n "$UUID2" ]; then
		HDD2=$(lsblk -lf | grep $UUID2 | awk '{print $1}')
		if [ -n "$HDD2" ]; then
			HDD2="/dev/$HDD2"
			echo "Found extra Hdd [$HDD2]"
		fi
	fi

	# Mount extra hdd
	sudo mount $HDD1 /home/Share
	mount | grep "$HDD1"
	if [ -n "$HDD2" ]; then
		sudo mount $HDD2 /home/Backup
		mount | grep "$HDD2"
	fi

	sleep 1
}

function umount_hdd()
{
	local HDDS=("/home/Backup" "/home/Share")

	for hdd in ${HDDS[@]}; do
		local MO=$(mount | grep $hdd)
		if [ -n "$MO" ]; then
			sudo fuser -kum $hdd
			sudo umount $hdd && echo "Umount $hdd"
		fi
	done
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
			systemctl status ${ser} | grep -B8 Active: | \
				sed -e "s/ active ([a-z]*)/$(echo -e "\e[1;32m&\e[0m")/g" \
					-e "s/ inactive ([a-z]*)/$(echo -e "\e[1;31m&\e[0m")/g"
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
