#!/usr/bin/env bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <DST>"
	exit 1
fi

DST="$1"

MSG=`xclip -o`
echo "Clipboard = [$MSG]"
MSG=$(echo "$MSG" | base64)

MSG="echo '${MSG}' | base64 -d > clipboard"
ssh -t ${DST} "${MSG}"
