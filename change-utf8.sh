#!/usr/bin/env bash

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
if [ $CMD == 1 ]; then
	echo -e "Already UTF-8\t[$FILE_NAME]"
	exit 1
fi

touch "${FILE_NAME}_"
if ! [ -f "${FILE_NAME}_" ]; then
	echo "touch: cannot touch '${FILE_NAME}_': Permission denied"
	exit 1
fi

iconv -c -f euc-kr -t utf-8 "$FILE_NAME" > "${FILE_NAME}_"
cat "${FILE_NAME}_" > "${FILE_NAME}"

rm -f "${FILE_NAME}_"
