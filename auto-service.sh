#!/usr/bin/env bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

COLOR_RED=`tput setaf 1`
COLOR_GREEN=`tput setaf 2`
COLOR_YELLOW=`tput setaf 3`
COLOR_BLUE=`tput setaf 4`
COLOR_WITHE=`tput setaf 7`
COLOR_RESET=`tput sgr0`

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
	# Find extra hdd1
	local NAME_HDD1="hdd1.txt"
	local UUID1=$(get_uuid $NAME_HDD1)
	if [ -z "$UUID1" ]; then
		echo "Cannot access '$NAME_HDD1': No such file"
		echo "You have to create a file '$NAME_HDD1' in the '$SCRIPTPATH'"
		echo "Enter the hdd uuid in the '$NAME_HDD1' file."
		return 1
	fi

	local HDD1="/dev/disk/by-uuid/$UUID1"
	if [ ! -e "$HDD1" ]; then
		echo "Not found extra HDD [$UUID1]"
		return 1
	fi

	echo "Found extra Hdd [$(realpath "$HDD1")]"

	# Find extra hdd2
	local NAME_HDD2="hdd2.txt"
	local UUID2=$(get_uuid $NAME_HDD2)
	local HDD2=""
	if [ -n "$UUID2" ]; then
		HDD2="/dev/disk/by-uuid/$UUID2"
		if [ ! -e "$HDD2" ]; then
			echo "Not found extra HDD [$UUID2]"
			return 1
		fi
		echo "Found extra Hdd [$(realpath "$HDD2")]"
	fi

	# Mount extra hdd
	local MOUNTED_HDD1=0
	if mountpoint -q /home/Share; then
		if [ "$(findmnt -nro UUID --target /home/Share)" != "$UUID1" ]; then
			echo "Another device is mounted on /home/Share"
			return 1
		fi
		echo "Share is already mounted with the expected UUID."
	else
		if ! sudo mount "$HDD1" /home/Share; then
			echo "Failed to mount $HDD1 on /home/Share"
			return 1
		fi
		MOUNTED_HDD1=1
	fi

	if [ "$(findmnt -nro UUID --target /home/Share)" != "$UUID1" ]; then
		echo "Failed to verify /home/Share mount"
		if [ "$MOUNTED_HDD1" -eq 1 ]; then
			sudo umount /home/Share
		fi
		return 1
	fi

	if [ -n "$HDD2" ]; then
		if mountpoint -q /home/Backup; then
			if [ "$(findmnt -nro UUID --target /home/Backup)" != "$UUID2" ]; then
				echo "Another device is mounted on /home/Backup"
				if [ "$MOUNTED_HDD1" -eq 1 ]; then
					sudo umount /home/Share
				fi
				return 1
			fi
			echo "Backup is already mounted with the expected UUID."
		elif ! sudo mount "$HDD2" /home/Backup; then
			echo "Failed to mount $HDD2 on /home/Backup"
			if [ "$MOUNTED_HDD1" -eq 1 ]; then
				sudo umount /home/Share
			fi
			return 1
		fi

		if [ "$(findmnt -nro UUID --target /home/Backup)" != "$UUID2" ]; then
			echo "Failed to verify /home/Backup mount"
			sudo umount /home/Backup
			if [ "$MOUNTED_HDD1" -eq 1 ]; then
				sudo umount /home/Share
			fi
			return 1
		fi
	fi
}

function umount_hdd()
{
	local HDDS=("/home/Backup" "/home/Share")

	local FAILED=0
	for hdd in ${HDDS[@]}; do
		if mountpoint -q "$hdd"; then
			if sudo umount "$hdd"; then
				echo "Umount $hdd"
			else
				echo "Failed to unmount $hdd: filesystem is busy."
				FAILED=1
			fi
		fi
	done

	return "$FAILED"
}

function start_service()
{
	local PARALLEL_SERVICE=()
	local idx
	local parallel_ser
	local ser

	for ser in "${LIST_SERVICE[@]}"; do
		if ! systemctl cat "$ser" > /dev/null 2>&1; then
			echo "Cannot find service: ${ser}"
			return 1
		fi
	done

	for idx in "${!LIST_SERVICE[@]}"; do
		ser=${LIST_SERVICE[$idx]}
		if [ "${LIST_START_MODE[$idx]}" = "parallel" ]; then
			PARALLEL_SERVICE+=("$ser")
			continue
		fi

		if [ "${#PARALLEL_SERVICE[@]}" -gt 0 ]; then
			if ! sudo systemctl start "${PARALLEL_SERVICE[@]}"; then
				echo "Failed to start parallel services: ${PARALLEL_SERVICE[*]}"
				return 1
			fi
			for parallel_ser in "${PARALLEL_SERVICE[@]}"; do
				echo "Start ${parallel_ser}"
			done
			PARALLEL_SERVICE=()
		fi

		if sudo systemctl start "$ser"; then
			echo "Start ${ser}"
		else
			echo "Failed to start ${ser}"
			return 1
		fi
	done

	if [ "${#PARALLEL_SERVICE[@]}" -gt 0 ]; then
		if ! sudo systemctl start "${PARALLEL_SERVICE[@]}"; then
			echo "Failed to start parallel services: ${PARALLEL_SERVICE[*]}"
			return 1
		fi
		for parallel_ser in "${PARALLEL_SERVICE[@]}"; do
			echo "Start ${parallel_ser}"
		done
	fi
}

function stop_service()
{
	local FAILED=0
	local idx=$(( ${#LIST_SERVICE[@]} -1 ))
	while [[ -1 -lt idx ]]; do
		local ser=${LIST_SERVICE[$idx]}
		if ! systemctl cat "$ser" > /dev/null 2>&1; then
			echo "Cannot find service: ${ser}"
			FAILED=1
		elif sudo systemctl stop "$ser"; then
			echo "Stop ${ser}"
		else
			echo "Failed to stop ${ser}"
			FAILED=1
		fi
		((idx--))
	done

	return "$FAILED"
}

function status_service()
{
	for ser in "${LIST_SERVICE[@]}"; do
		local CMD=`systemctl is-enabled ${ser} 2>&1 | grep Failed`
		if [ -z "$CMD" ]; then
			systemctl status ${ser} | grep -B8 Active: | \
				sed -e "s/ active ([a-z]*)/$(echo "${COLOR_GREEN}&${COLOR_RESET}")/g" \
					-e "s/ inactive ([a-z]*)/$(echo "${COLOR_RED}&${COLOR_RESET}")/g"
			echo ""
		fi
	done
}

function load_service_list()
{
	local MODE="serial"
	local LINE=""
	local LINE_NUMBER=0
	local SERVICE=""

	LIST_SERVICE=()
	LIST_START_MODE=()

	while IFS= read -r LINE || [ -n "$LINE" ]; do
		((LINE_NUMBER++))
		SERVICE="${LINE#"${LINE%%[![:space:]]*}"}"
		SERVICE="${SERVICE%"${SERVICE##*[![:space:]]}"}"

		case "$SERVICE" in
			""|\#*)
				continue
				;;
			"[serial]")
				MODE="serial"
				;;
			"[parallel]")
				MODE="parallel"
				;;
			\[*\])
				echo "Unknown service list section at line ${LINE_NUMBER}: ${SERVICE}"
				return 1
				;;
			*[[:space:]]*)
				echo "Invalid service name at line ${LINE_NUMBER}: ${SERVICE}"
				return 1
				;;
			*)
				LIST_SERVICE+=("$SERVICE")
				LIST_START_MODE+=("$MODE")
				;;
		esac
	done < "${SCRIPTPATH}/service.list"

	if [ "${#LIST_SERVICE[@]}" -eq 0 ]; then
		echo "No services found in 'service.list'"
		return 1
	fi
}

if ! [ -f "${SCRIPTPATH}/service.list" ]; then
	echo "Cannot access 'service.list': No such file"
	echo "You have to create a file 'service.list' in the '$SCRIPTPATH'"
	exit 1
fi

if ! load_service_list; then
	exit 1
fi

if [ $# -eq 0 ]; then
	help
fi

case $1 in
	start)
		if ! mount_hdd; then
			echo "Failed to mount required storage. Services will not be started."
			exit 1
		fi
		start_service || exit 1
		;;
	stop)
		if ! stop_service; then
			echo "Failed to stop services. Storage will remain mounted."
			exit 1
		fi
		umount_hdd || exit 1
		;;
	restart)
		if ! stop_service; then
			echo "Failed to stop services. Storage will remain mounted."
			exit 1
		fi
		umount_hdd || exit 1
		if ! mount_hdd; then
			echo "Failed to mount required storage. Services will not be started."
			exit 1
		fi
		start_service || exit 1
		;;
	status)
		status_service
		;;
	*)
		help
		;;
esac
