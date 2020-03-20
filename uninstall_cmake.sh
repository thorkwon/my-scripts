#!/bin/bash

INSTALL_LIST="install_manifest.txt"

CMD=`ls | grep install_manifest.txt`

if [ -z $CMD ]; then
	echo "${INSTALL_LIST}: Not found"
	exit 1
fi

echo -e "=== Remove list ==="
cat ${INSTALL_LIST}

echo -e "\n=== Remove ==="
cat ${INSTALL_LIST} | sudo xargs rm
cat ${INSTALL_LIST} | xargs -L1 dirname | sudo xargs rmdir -p
