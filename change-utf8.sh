#!/bin/bash

if [ $# == 0 ]; then
	echo "Usage: change-utf8.sh [filename]"
	exit 1
fi

# Backup env IFS and then set IFS to newline
IFS_BACKUP="$IFS"
IFS=$'\n'

FILE_NAME=$1

for token in $@; do
	if [ "$token" == "$1" ]; then
		continue
	fi
	FILE_NAME="$FILE_NAME"$' '"$token"
done

CMD=`file $FILE_NAME | grep UTF | wc -l`
USER=`ls -l $FILE_NAME | awk '{print $3}'`
GROUP=`ls -l $FILE_NAME | awk '{print $4}'`

if [ $CMD == 1 ]; then
	echo "Already UTF-8"$'\t'"[$FILE_NAME]"
	# Restore IFS
	IFS=$IFS_BACKUP
	exit 1
fi

touch ${FILE_NAME}_

iconv -c -f euc-kr -t utf-8 $FILE_NAME > ${FILE_NAME}_

rm -f $FILE_NAME
mv ${FILE_NAME}_ $FILE_NAME

sudo chown $USER:$GROUP $FILE_NAME

# Restore IFS
IFS=$IFS_BACKUP
