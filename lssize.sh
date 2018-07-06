#!/bin/bash

# Backup env IFS and then set IFS to newline
IFS_BACKUP="$IFS"
IFS=$'\n'

ARR_LIST=(`ls -1`)

for list in ${ARR_LIST[@]}; do
	du -sh "$list"
done

# Restore IFS
IFS=$IFS_BACKUP
