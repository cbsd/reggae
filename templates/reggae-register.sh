#!/bin/sh

ACTION=$1
IP=$2
NAME=$3
DOMAIN=$4

ZONE_FILE="/var/unbound/conf.d/${DOMAIN}.zone"
IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${ZONE_FILE}" | /usr/bin/head -n 1 | /usr/bin/cut -f 1 -d ':'`
EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${IGNORE_LINES}d" "${ZONE_FILE}" | /usr/bin/grep "^${NAME}"`

REVERSE_ZONE=`echo ${IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
REVERSE_ZONE_FILE="/var/unbound/conf.d/${REVERSE_ZONE}.zone"
REVERSE_IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${REVERSE_ZONE_FILE}" | /usr/bin/head -n 1 | /usr/bin/cut -f 1 -d ':'`
LAST_OCTET=`echo "${IP}" | awk -F '.' '{print $4}'`
REVERSE_EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${REVERSE_IGNORE_LINES}d" "${REVERSE_ZONE_FILE}" | /usr/bin/grep "^${LAST_OCTET} "`


if [ "${ACTION}" = "add" ]; then
  /sbin/pfctl -t cbsd -T add $IP
  if [ ! -z "${NAME}" ]; then
    # Forward
    if [ -z "${EXISTING_DNS_ENTRY}" ]; then
      /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
    else
      /usr/bin/sed -i "" "s/^${NAME} *A .*/${NAME}    A   ${IP}/" "${ZONE_FILE}"
    fi

    # Reverse
    if [ -z "${REVERSE_EXISTING_DNS_ENTRY}" ]; then
        /bin/echo "${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
    else
        /usr/bin/sed -i "" "s/^${LAST_OCTET} *PTR .*/${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}./" "${REVERSE_ZONE_FILE}"
    fi
  fi
elif [ "${ACTION}" = "delete" ]; then
  /sbin/pfctl -t cbsd -T delete $IP
  /usr/bin/sed -i "" "/^.* *A *${IP}$/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}"
fi

local-unbound-control reload
