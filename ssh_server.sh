#!/bin/bash

MSG=$(nmap -p 22 192.168.0.10 --host-timeout .2 | grep open)

if [ -n "$MSG" ]; then
	ssh khg@192.168.0.10
else
	ssh -p 50022 khg@khg.woobi.co.kr
fi
