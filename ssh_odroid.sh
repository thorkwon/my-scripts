#bin/bash

MSG=$(ping -W 1 -c 1 192.168.0.10 | grep ttl=64)

if [ -n "$MSG" ]; then
	ssh odroid@192.168.0.10
else
	ssh -p 50022 odroid@khg.woobi.co.kr
fi
