#!/bin/bash

if [ -z $1 ] | [ -z $2 ]; then
	echo "Usage: my-rdesktop.sh <ip> <user>"
	exit 1
fi

IP=$1
USER=$2

sudo rdesktop -u $USER -k ko -g 97% -a 16 -PKD $IP
