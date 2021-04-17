#!/usr/bin/env bash

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
if ! [ -f "${SCRIPTPATH}/server.list" ]; then
	echo "Cannot access 'server.list': No such file"
	echo "You have to create a file 'server.list' in the '$SCRIPTPATH'"
	exit 1
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 <cmd>"
	exit 1
fi

CMD=$@
echo "Sent cmd: [$CMD]"
SERVER_LIST=`cat ${SCRIPTPATH}/server.list`
for server in $SERVER_LIST; do
	echo "=============== $server ==============="
	ssh -t $server ${CMD}
	echo -e "\n"
done
