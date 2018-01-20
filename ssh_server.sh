#!/bin/bash

MSG=$(nmap -p 22 192.168.0.10 --host-timeout .2 | grep open)

if [ -n "$MSG" ]; then
	echo "local network"
	ssh 192.168.0.10
else
	echo "global network"
	ssh server
fi
