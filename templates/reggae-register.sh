#!/bin/sh

ACTION=$1
IP=$2
NAME=`echo $3 | cut -f 1 -d '.'`
DOMAIN=$4

ZONE_FILE="/var/unbound/zones/${DOMAIN}.zone"
REVERSE_ZONE=`echo ${IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
REVERSE_ZONE_FILE="/var/unbound/zones/${REVERSE_ZONE}.zone"
LAST_OCTET=`echo "${IP}" | awk -F '.' '{print $4}'`
TEMP_FILE=`mktemp`


/usr/bin/sed "/^.* *A *${IP}$/d" "${ZONE_FILE}" >"${TEMP_FILE}"
/bin/cat "${TEMP_FILE}" >"${ZONE_FILE}"
/usr/bin/sed "/^${NAME}    A *.*$/d" "${ZONE_FILE}" >"${TEMP_FILE}"
/bin/cat "${TEMP_FILE}" >"${ZONE_FILE}"
/usr/bin/sed "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}" >"${TEMP_FILE}"
/bin/cat "${TEMP_FILE}" >"${REVERSE_ZONE_FILE}"

rm "${TEMP_FILE}"

if [ "${ACTION}" = "add" ]; then
  /sbin/pfctl -t cbsd -T add $IP
  if [ ! -z "${NAME}" ]; then
    /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
    /bin/echo "${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
  fi
elif [ "${ACTION}" = "delete" ]; then
  /sbin/pfctl -t cbsd -T delete $IP
fi

local-unbound-control reload
