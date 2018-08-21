#!/bin/sh

ACTION=$1
IP=$2
CLIENT_NAME=$3

if [ "${ACTION}" = "commit" ]; then
  /sbin/pfctl -t cbsd -T add $IP || true
  case ${CLIENT_NAME} in
    base*)
      echo "${IP} ${CLIENT_NAME}" >/tmp/commit.txt
      ;;
  esac
elif [ "${ACTION}" = "release" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
elif [ "${ACTION}" = "expiry" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
fi
