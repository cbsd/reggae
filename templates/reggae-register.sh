#!/bin/sh

ACTION=$1
IP=$2
NAME=$3
DOMAIN=$4

ZONE_FILE="/var/unbound/conf.d/${DOMAIN}.zone"
REVERSE_ZONE=`echo ${IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
REVERSE_ZONE_FILE="/var/unbound/conf.d/${REVERSE_ZONE}.zone"
LAST_OCTET=`echo "${IP}" | awk -F '.' '{print $4}'`


/usr/bin/sed -i "" "/^.* *A *${IP}$/d" "${ZONE_FILE}"
/usr/bin/sed -i "" "/^${NAME} *A *.*$/d" "${ZONE_FILE}"
/usr/bin/sed -i "" "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}"

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
