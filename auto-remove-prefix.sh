#!/usr/bin/env bash

if [ $# != 1 ]; then
	echo "Usage: $0 <prefix>"
	exit 1
fi

PREFIX=$1
FindRoot="."

find ${FindRoot} -name "${PREFIX}*" | while read line; do
	fix_filename=$(echo "$line" | sed -e "s/${PREFIX}//g")

	echo "Fix: ${line} => ${fix_filename}"
	mv ${line} ${fix_filename}
done
