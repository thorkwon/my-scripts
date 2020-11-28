#!/usr/bin/env bash

function set_ifs()
{
	# Backup env IFS and then set IFS to newline
	IFS_BACKUP="$IFS"
	IFS=$'\n'
}

function restore_ifs()
{
	# Restore IFS
	IFS=$IFS_BACKUP
}

function help()
{
	echo "Usage: $0 [OPTION]"
	echo "Options:"
	echo "  -t		sort by modification time, newest first"
	echo "  -h		display this help"
	restore_ifs
	exit 1
}

set_ifs
ARR_LIST=(`ls -1`)
while getopts "th" opt; do
	case $opt in
		t)
			ARR_LIST=(`ls -1t`)
			;;
		h)
			help
			;;
		th)
			echo "th"
			;;
		*)
			help
			;;
	esac
done

for list in ${ARR_LIST[@]}; do
	du -sh "$list"
done

restore_ifs
