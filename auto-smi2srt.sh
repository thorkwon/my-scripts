#!/bin/sh
# Find SMI file recursively script by Taylor Starfield

FindRoot=./test

find $FindRoot -name '[^.]*.smi' | while read line; do
  if [ -f "${line%.smi}.srt" ]; then
    continue
  fi
  python subtitle-convert.py "$line"
  chmod +x "${line%.smi}.srt"

done
