#!/bin/sh
set -eu

output=$(pkg-config "$@")
printf '%s\n' "$output" | sed \
    -e 's#-I/usr/include/x86_64-linux-gnu##g' \
    -e 's#  *# #g'
