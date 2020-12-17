#!/usr/bin/env bash

OS=`uname`
if ! [ "$OS" = "Darwin" ]; then
	exit 0
fi

STATUS=`sysctl -a | grep "debug.lowpri_throttle_enabled" | awk '{print $2}'`
if [ $STATUS -eq 0 ]; then
	echo "Already done setup inital mac"
	exit 0
fi

sudo sysctl debug.lowpri_throttle_enabled=0
sudo pfctl -evf /etc/pf.conf
