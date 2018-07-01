#!/bin/bash

# init apt-get install for ubuntu 16.04

if [ -z "$1" ]; then
	echo "Usage: ./setup-apt-install.sh [base]|[all]"
	exit 1
fi

# base
if [ "$1" == "base" -o "$1" == "all" ]; then
	echo "Install package for base"
	sudo apt -y install nmap
	sudo apt -y install hping3
	sudo apt -y install qbittorrent
	sudo apt -y install rdesktop
	sudo apt -y install samba
	sudo apt -y install sendemail
	sudo apt -y install ssh
	sudo apt -y install terminator
	sudo apt -y install vim
	sudo apt -y install vlc
	sudo apt -y install xclip
	sudo apt -y install git
	sudo apt -y install git-email
	sudo apt -y install tig
	sudo apt -y install tree
	sudo apt -y install ccache
	sudo apt -y install cscope
	sudo apt -y install ctags
	sudo apt -y install gcp
	sudo apt -y install dconf-tools
	sudo apt -y install cifs-utils
	sudo apt -y install dkms
	sudo apt -y install screen
fi

# coding and compiler
if [ "$1" == "all" ]; then
	echo "Install package for coding"
	sudo apt -y install cmake
	sudo apt -y install autoconf
	sudo apt -y install autotools-dev
	sudo apt -y install gawk git-core
	sudo apt -y install diffstat unzip texinfo gcc-multilib
	sudo apt -y install build-essential chrpath socat libsdl1.2-dev
	sudo apt -y install python-pip
	sudo apt -y install python3-pip
	sudo apt -y install g++
	sudo apt -y install gcc
	sudo apt -y install g++-arm-linux-gnueabi
	sudo apt -y install gcc-arm-linux-gnueabi
	sudo apt -y install device-tree-compiler
	sudo apt -y install lthor
	sudo apt -y install minicom
	sudo apt -y install acpi

	sudo apt -y install android-tools
	sudo apt -y install android-tools-adb android-tools-fastboot
	sudo apt -y install libqt4-dev libncurses5-dev
	sudo apt -y install curlftpfs
	sudo apt -y install emdebian-archive-keyring
	sudo apt -y install fbterm
	sudo apt -y install ia32-libs-multiarch
	sudo apt -y install lzop
fi
