#!/bin/sh

ACTION=$1
IP=$2

if [ "${ACTION}" = "commit" ]; then
  /sbin/pfctl -t cbsd -T add $IP || true
elif [ "${ACTION}" = "release" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
elif [ "${ACTION}" = "expiry" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
fi
