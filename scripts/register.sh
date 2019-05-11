#!/bin/sh


SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi
. "${PROJECT_ROOT}/scripts/default.conf"

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
NAME=${jname}
IP=${ipv4_first}
ACTION="${1}"
PF_ACTION="add"
DOMAIN=`reggae get-config DOMAIN`

ZONE_FILE="/var/unbound/conf.d/${DOMAIN}.zone"
IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${ZONE_FILE}" | /usr/bin/cut -f 1 -d ':'`
EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${IGNORE_LINES}d" "${ZONE_FILE}" | /usr/bin/grep "^${NAME}"`

REVERSE_ZONE=`echo ${IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
REVERSE_ZONE_FILE="/var/unbound/conf.d/${REVERSE_ZONE}.zone"
REVERSE_IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${REVERSE_ZONE_FILE}" | /usr/bin/head -n 1 | /usr/bin/cut -f 1 -d ':'`
REVERSE_EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${REVERSE_IGNORE_LINES}d" "${REVERSE_ZONE_FILE}" | /usr/bin/grep "^${IP}"`
LAST_OCTET=`echo "${IP}" | awk -F '.' '{print $4}'`

if [ "${ACTION}" = "deregister" ]; then
  PF_ACTION="delete"
fi


if [ "${ACTION}" = "register" ]; then
  # Forward
  if [ -z "${EXISTING_DNS_ENTRY}" ]; then
    echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
  else
    /usr/bin/sed -i "" "s/^${NAME} *A .*/${NAME}    A   ${IP}/" "${ZONE_FILE}"
  fi

  # Reverse
  if [ -z "${REVERSE_EXISTING_DNS_ENTRY}" ]; then
      /bin/echo "${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
  else
      /usr/bin/sed -i "" "s/^${LAST_OCTET} *PTR .*/${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}./" "${REVERSE_ZONE_FILE}"
  fi
else
  /usr/bin/sed -i "" "/^${NAME} *A *.*/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}"
fi
local-unbound-control reload
pfctl -t cbsd -T ${PF_ACTION} ${IP}
