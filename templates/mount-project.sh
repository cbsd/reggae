#!/bin/sh

trap "rm -rf ${0}" HUP INT ABRT BUS TERM EXIT

if [ ! -e /usr/src/Makefile ]; then
  mdo mount -t nfs INTERFACE_IP:${1} /usr/src
fi
