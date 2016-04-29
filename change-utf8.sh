#!/bin/bash

touch "_$1"

iconv -c -f euc-kr -t utf-8 "$1" > "_$1"

rm -f "$1"
mv "_$1" "$1"
