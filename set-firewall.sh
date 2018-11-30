#!/bin/bash

help() {
	echo "Usage: set-firewall-rule.sh -I [ip ...]"
	echo "       set-firewall-rule.sh -D [ip ...]"
	echo "       set-firewall-rule.sh -D all"
	echo "Options:"
	echo "  -I        insert firewall reject rules for IP"
	echo "  -D        delete firewall reject rules for IP"
	echo "  -D all    delete firewall reject rules for applied IPs"
	exit 1
}

is_ip() {
	cmd=`ping -c1 -w1 $1 2>&1 | grep statistics`
	if [ -z "$cmd" ]; then
		echo "It is not IP [$1]"
		ret=1
	else
		ret=0
	fi
}

if [ -z "`sudo iptables -nL INPUT | grep f2b-sshd`" ]; then
	echo "Notice:"
	echo "        There is no f2b-sshd rule in iptables."
	echo "        You need to install the fail2ban package."
	echo "        If it is installed, you need to start fail2ban."
	exit 1
fi

if [ $# == 0 ]; then
	help
fi

while getopts "I:D:" opt; do
	case $opt in
	I)
		set -- "${@:2:$#}"
		for ip in $@; do
			is_ip $ip
			if [ $ret == 0 ]; then
				sudo iptables -I f2b-sshd 1 -s $ip -j REJECT
				echo "REJECT [$ip]"
			fi
		done
		;;
	D)
		if [ "$2" == "all" ]; then
			echo "Delete all reject rules"
			ip_list=`sudo iptables -nvL | grep REJECT | awk '{print $8}'`
			for ip in $ip_list; do
				sudo iptables -D f2b-sshd -s $ip -j REJECT
			done
			break
		fi

		set -- "${@:2:$#}"
		for ip in $@; do
			is_ip $ip
			if [ $ret == 0 ]; then
				sudo iptables -D f2b-sshd -s $ip -j REJECT
			fi
		done
		;;
	?)
		help ;;
	esac
done

echo "__________________________________________________________________________________________________________________________"
sudo iptables -nvL
