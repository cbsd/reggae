#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: $0 mac-address" >&2
  exit 1
fi

(
  echo server MASTER_IP
  echo connect
  echo new lease
  echo set hardware-address = $1
  echo open
) | omshell | grep '^clientIP =' | cut -f 2 -d '"'

