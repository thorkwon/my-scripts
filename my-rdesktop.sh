#!/bin/bash

if [ -z $1 ] | [ -z $2 ]; then
	echo "Usage: my-rdesktop.sh <ip> <user>"
	exit 1
fi

sudo rdesktop -u $2 -k ko -g 96% -PKD $1
