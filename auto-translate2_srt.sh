#!/usr/bin/env bash
# English srt subtitles to Korean srt translation.

if [ $# != 1 ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

if [ -f "${1}.backup" ]; then
	echo "Already translation Done..."
	exit 0
fi

USER=`ls -l "$1" | awk '{print $3}'`
GROUP=`ls -l "$1" | awk '{print $4}'`

python3 ${SCRIPTPATH}/translate2ko_srt.py $1
sudo chown $USER:$GROUP "$1"
