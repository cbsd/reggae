#!/bin/sh

ACTION=$1
IP=$2
NAME=$3
ZONE_FILE="/var/unbound/conf.d/cbsd.zone"
IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${ZONE_FILE}" | /usr/bin/head -n 1 | /usr/bin/cut -f 1 -d ':'`
EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${IGNORE_LINES}d" "${ZONE_FILE}" | /usr/bin/grep "^${NAME}"`


if [ "${ACTION}" = "add" ]; then
  /sbin/pfctl -t cbsd -T add $IP
  if [ ! -z "${NAME}" ]; then
    if [ -z "${EXISTING_DNS_ENTRY}" ]; then
      /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
    else
      /usr/bin/sed -i "" "s/^${NAME} *A .*/${NAME}    A   ${IP}/" "${ZONE_FILE}"
    fi
  fi
elif [ "${ACTION}" = "delete" ]; then
  /sbin/pfctl -t cbsd -T delete $IP
  /usr/bin/sed -i "" "/^.* *A *${IP}$/d" "${ZONE_FILE}"
fi

local-unbound-control reload
