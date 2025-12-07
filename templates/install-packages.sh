#!/bin/sh

trap "rm -rf ${0}" HUP INT ABRT BUS TERM  EXIT

if [ -z "${1}" ]; then
  exit 0
fi
mdo pkg install -y ${@}
