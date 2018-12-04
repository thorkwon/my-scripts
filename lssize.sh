#!/bin/bash

help() {
	echo "Usage: lssize.sh [OPTION]"
	echo "Options:"
	echo "  -t		sort by modification time, newest first"
	echo "  -h		display this help"
	exit 1
}

# Backup env IFS and then set IFS to newline
IFS_BACKUP="$IFS"
IFS=$'\n'

ARR_LIST=(`ls -1`)
while getopts "th" opt; do
	case $opt in
		t)
			ARR_LIST=(`ls -1t`)
			;;
		h)
			help
			;;
		*)
			help
			;;
	esac
done

for list in ${ARR_LIST[@]}; do
	du -sh "$list"
done

# Restore IFS
IFS=$IFS_BACKUP
