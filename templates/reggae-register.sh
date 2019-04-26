#!/bin/sh

ACTION=$1
IP=$2
JAIL_NAME=$3
ZONE_FILE="/var/unbound/conf.d/cbsd.zone"
IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${ZONE_FILE}" | /usr/bin/cut -f 1 -d ':'`
EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${IGNORE_LINES}d" "${ZONE_FILE}" | /usr/bin/grep "^${JAIL_NAME}"`


if [ "${ACTION}" = "add" ]; then
  /sbin/pfctl -t cbsd -T add $IP || true
  if [ ! -z "${JAIL_NAME}" ]; then
    if [ -z "${EXISTING_DNS_ENTRY}" ]; then
      /bin/echo "${JAIL_NAME}    A   ${IP}" >>"${ZONE_FILE}"
    else
      /usr/bin/sed -i "" "s/^${JAIL_NAME} *A .*/${JAIL_NAME}    A   ${IP}/" "${ZONE_FILE}"
    fi
  fi
elif [ "${ACTION}" = "delete" ]; then
  /sbin/pfctl -t cbsd -T delete $IP || true
  /usr/bin/sed -i "" "s/^${JAIL_NAME} *A .*\n//" "${ZONE_FILE}" >"${TEMP_FILE}"
fi

local-unbound-control reload
