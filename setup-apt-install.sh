#!/bin/bash

# init apt install for ubuntu 16.04 or 18.04

if [ -z "$1" ]; then
	echo "Usage: setup-apt-install.sh <base | all>"
	exit 1
fi

CMD=`dpkg -l | grep gnome-control`
if [ -n "$CMD" ]; then
	echo "The gnome is used."
	FLAG_USED_GNOME=1
	PKG_LISTS="
	gnome-tweak-tool
	ubuntu-restricted-extras
	net-tools
	chrome-gnome-shell
	x11-utils gnome-shell-extension-dashtodock
	"
	sudo apt -y install $PKG_LISTS
else
	FLAG_USED_GNOME=0
fi

# base
if [ "$1" == "base" -o "$1" == "all" ]; then
	echo "Add apt repo"
	sudo add-apt-repository ppa:dawidd0811/neofetch
	sudo find /etc/apt/ -name "*.save" -exec rm {} \;

	if [ $FLAG_USED_GNOME == 0 ]; then
		sudo apt update
	fi

	echo "Install package for base"
	PKG_LISTS="
	neofetch
	nmap
	hping3
	iperf3
	qbittorrent
	rdesktop
	samba
	sendemail
	ssh
	terminator
	vim
	vlc
	xclip
	git
	git-email
	tig
	tree
	ccache
	cscope
	ctags
	gcp
	cifs-utils
	dkms
	screen
	curl
	fcitx-hangul
	aria2
	ffmpeg
	speedtest-cli

	cmake
	autoconf
	autotools-dev
	gawk git-core
	diffstat unzip texinfo gcc-multilib
	build-essential chrpath socat libsdl1.2-dev
	python3-pip
	g++
	gcc
	"
	sudo apt -y install $PKG_LISTS
fi

# coding and compiler
if [ "$1" == "all" ]; then
	echo "Install package for coding"
	PKG_LISTS="
	g++-arm-linux-gnueabi
	gcc-arm-linux-gnueabi
	device-tree-compiler
	flex
	bison
	lthor
	minicom
	android-tools-adb android-tools-fastboot
	libqt4-dev libncurses5-dev
	curlftpfs
	emdebian-archive-keyring
	fbterm
	lzop
	"
	sudo apt -y install $PKG_LISTS
fi
