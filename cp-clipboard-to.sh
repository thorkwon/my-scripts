#!/usr/bin/env bash

if [ $# == 0 ]; then
	echo "Usage: $0 <DST>"
	exit 1
fi

DST="$1"

MSG=`xclip -o`
echo "Clipboard = [$MSG]"

MSG="echo '${MSG}' >> clipboard"
ssh -t ${DST} ${MSG}
