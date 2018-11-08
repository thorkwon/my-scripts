#!/bin/bash
# Find SMI file recursively script by Taylor Starfield

if [ $# != 1 ]; then
	echo "Usage: auto-smi2srt.sh [filename | directory]"
	exit 1
fi

FindRoot=$1
find $FindRoot -name '[^.]*.smi' | while read line; do
	if [ -f "${line%.smi}.srt" ]; then
		continue
	fi

	python smi2srt.py "$line"
done
