#!/usr/bin/env bash

COLOR_GREEN=$(tput setaf 2)
COLOR_RESET=$(tput sgr0)

CMD=$@
echo "CMD : [$CMD]"

while true; do
	$CMD > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo -en "\n${COLOR_GREEN}Done${COLOR_RESET}\n"
		break
	fi
	sleep 0.5
	echo -en "."

done
