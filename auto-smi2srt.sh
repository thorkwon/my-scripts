#!/usr/bin/env bash
# Find SMI file recursively script by Taylor Starfield

if [ $# != 1 ]; then
	echo "Usage: $0 <filename | directory>"
	exit 1
fi

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

FindRoot=$1
find "$FindRoot" -name '[^.]*.smi' | while read line; do
	if [ -f "${line%.smi}.srt" ]; then
		continue
	fi

	python3 ${SCRIPTPATH}/smi2srt.py "$line"

	USER=`ls -l "$line" | awk '{print $3}'`
	GROUP=`ls -l "$line" | awk '{print $4}'`
	if [ -f "${line%.smi}.srt" ]; then
		sudo chown $USER:$GROUP "${line%.smi}.srt"
		sudo mv "${line}" "${line}.backup"
	fi
done
