#!/bin/bash

CMD=`file $1 | grep UTF | wc -l`
USER=`ls -l $1 | awk '{print $3}'`
GROUP=`ls -l $1 | awk '{print $4}'`

if [ $CMD == 1 ]; then
	echo "Already UTF-8"
	exit 1
fi

touch $1_

iconv -c -f euc-kr -t utf-8 $1 > $1_

rm -f $1
mv $1_ $1

sudo chown $USER:$GROUP $1
