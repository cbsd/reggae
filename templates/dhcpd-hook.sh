#!/bin/sh

ACTION=$1
IP=$2
MAC=$3

if [ "${ACTION}" = "commit" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
  /sbin/pfctl -t cbsd -T add $IP || true
elif [ "${ACTION}" = "release" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
fi
