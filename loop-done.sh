#!/usr/bin/env bash

COLOR_GREEN=$(tput setaf 2)
COLOR_RESET=$(tput sgr0)

CMD=$@
echo "CMD : [$CMD]"

while true; do
	$CMD
	if [ $? -eq 0 ]; then
		echo "${COLOR_GREEN}Done${COLOR_RESET}"
		break
	fi
	sleep 0.5
done
