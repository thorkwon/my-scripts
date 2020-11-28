#!/usr/bin/env bash

INSTALL_LIST="install_manifest.txt"

CMD=`ls | grep install_manifest.txt`
if [ -z "$CMD" ]; then
	echo "${INSTALL_LIST}: Not found"
	exit 1
fi

CMD=`cat ${INSTALL_LIST} | xargs ls 2>&1 | grep "No such file or directory"`
if ! [ -z "$CMD" ]; then
	echo "Already removed..."
	exit 0
fi

echo -e "=== Remove list ==="
cat ${INSTALL_LIST}
cat ${INSTALL_LIST} | sudo xargs rm
cat ${INSTALL_LIST} | xargs -L1 dirname | sudo xargs rmdir -p 2>/dev/null
echo -e "\n=== All Removed ==="
