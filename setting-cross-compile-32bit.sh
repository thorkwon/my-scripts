#!/bin/bash

# cross compile 32bit

sudo apt-get -y install emdebian-archive-keyring
sudo apt-get -y install libc6-armel-cross libc6-dev-armel-cross
sudo apt-get -y install binutils-arm-linux-gnueabi
sudo apt-get -y install gcc-arm-linux-gnueabi
sudo apt-get -y install g++-arm-linux-gnueabi
sudo apt-get -y install u-boot-tools
sudo apt-get -y install libncurses5-dev
