#!/usr/bin/env bash

free -h
echo "_________________________________________________________________________"
sudo sync
sudo sysctl -w vm.drop_caches=3
sudo sync
echo "_________________________________________________________________________"
free -h
