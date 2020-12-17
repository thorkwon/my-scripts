#!/usr/bin/env bash

# Readme
# If you want use this script, modify the '/etc/fail2ban/action.d/iptables-common.conf' file as follows.
#
# In the iptables-common.conf:
# comment the line
# blocktype = REJECT --reject-with icmp-port-unreachable
#
# create the line
# blocktype = DROP

function help()
{
	echo "Usage: $0 -I <ip ...>"
	echo "       $0 -D <ip ...>"
	echo "       $0 -D all"
	echo "Options:"
	echo "  -I        insert firewall drop rules for IP"
	echo "  -D        delete firewall drop rules for IP"
	echo "  -D all    delete firewall drop rules for applied IPs"
	exit 1
}

function is_ip()
{
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

if [ $# -eq 0 ]; then
	help
fi

while getopts "I:D:" opt; do
	case $opt in
		I)
			set -- "${@:2:$#}"
			for ip in $@; do
				is_ip $ip
				if [ $ret -eq 0 ]; then
					sudo iptables -I f2b-sshd 1 -s $ip -j DROP
					echo "DROP [$ip]"
				fi
			done
			;;
		D)
			if [ "$2" = "all" ]; then
				echo "Delete all drop rules"
				ip_list=`sudo iptables -nvL | grep DROP | awk '{print $8}'`
				for ip in $ip_list; do
					sudo iptables -D f2b-sshd -s $ip -j DROP
				done
				break
			fi

			set -- "${@:2:$#}"
			for ip in $@; do
				is_ip $ip
				if [ $ret -eq 0 ]; then
					sudo iptables -D f2b-sshd -s $ip -j DROP
				fi
			done
			;;
		*)
			help
			;;
	esac
done

echo "__________________________________________________________________________________________________________________________"
sudo iptables -nvL
