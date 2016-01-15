#!/bin/bash

echo "______________________________________________________________update"
sudo apt-get update
echo "______________________________________________________________updgrade"
sudo apt-get -y upgrade
echo "______________________________________________________________-f install"
sudo apt-get -f install
