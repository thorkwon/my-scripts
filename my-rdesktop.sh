#!/usr/bin/env bash

if [ -z $1 ] | [ -z $2 ]; then
	echo "Usage: $0 <ip> <user>"
	exit 1
fi

IP=$1
USER=$2

sudo rdesktop -u $USER -k ko -g 97% -a 16 -PKD $IP
