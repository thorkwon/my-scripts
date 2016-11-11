#!/bin/bash

MSG=$(nmap -p 22 192.168.0.10 --host-timeout .2 | grep open)

if [ -n "$MSG" ]; then
	ssh odroid@192.168.0.10
else
	ssh -p 50022 odroid@khg.woobi.co.kr
fi
