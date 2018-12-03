#!/bin/bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
if ! [ -f "${SCRIPTPATH}/server.list" ]; then
	echo "Cannot access 'server.list': No such file"
	echo "You have to create a file 'server.list' in the '$SCRIPTPATH'"
	exit 1
fi

if [ $# == 0 ]; then
	echo "Usage: cmd-remote.sh <cmd>"
	exit 1
fi

ROOT_PW=""
if [ "$1" == "sudo" ]; then
	echo "[sudo] password:"
	read -s ROOT_PW
fi

if [ "$ROOT_PW" == "" ]; then
	CMD=$@
else
	CMD="echo $ROOT_PW | sudo -S"

	set -- "${@:2:$#}"
	for token in $@; do
		CMD="$CMD"$' '"$token"
	done
fi

echo "Sent cmd: [$CMD]"
SERVER_LIST=`cat ${SCRIPTPATH}/server.list`
for server in $SERVER_LIST; do
	echo "=============== $server ==============="
	ssh -t $server ${CMD}
	echo -e "\n"
done
