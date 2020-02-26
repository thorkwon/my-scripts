#!/bin/bash

if [ $# == 0 ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi

FILE_NAME=$@

if ! [ -f "$FILE_NAME" ]; then
	echo -e "This is a directory, only use file:\t[$FILE_NAME]"
	exit 1
fi

CMD=`file "$FILE_NAME" | grep UTF | wc -l`
USER=`ls -l "$FILE_NAME" | awk '{print $3}'`
GROUP=`ls -l "$FILE_NAME" | awk '{print $4}'`

if [ $CMD == 1 ]; then
	echo -e "Already UTF-8\t[$FILE_NAME]"
	exit 1
fi

touch "${FILE_NAME}_"

iconv -c -f euc-kr -t utf-8 "$FILE_NAME" > "${FILE_NAME}_"

rm -f "$FILE_NAME"
mv "${FILE_NAME}_" "$FILE_NAME"

sudo chown $USER:$GROUP "$FILE_NAME"
