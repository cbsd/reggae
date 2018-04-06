#!/bin/sh

ACTION=$1
IP=$2
MAC=$3

if [ "${ACTION}" = "commit" ]; then
  /sbin/pfctl -t cbsd -T delete $IP
  /sbin/pfctl -t cbsd -T add $IP
elif [ "${ACTION}" = "release" ]; then
  /sbin/pfctl -t cbsd -T delete $IP
fi
