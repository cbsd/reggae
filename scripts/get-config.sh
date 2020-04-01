#!/bin/sh

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

raw_variable=`echo "$"$1`
variable=`eval "echo" $raw_variable`
echo $variable
