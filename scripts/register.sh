#!/bin/sh


SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi
. "${PROJECT_ROOT}/scripts/default.conf"

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
JAIL_NAME=${jname}
JAIL_IP=${ipv4_first}
ACTION="${1}"
PF_ACTION="add"
ZONE_FILE="/var/unbound/conf.d/cbsd.zone"

if [ "${ACTION}" = "deregister" ]; then
  PF_ACTION="delete"
fi

IGNORE_LINES=`/usr/bin/grep -n ORIGIN "${ZONE_FILE}" | /usr/bin/cut -f 1 -d ':'`
EXISTING_DNS_ENTRY=`/usr/bin/sed -e "1,${IGNORE_LINES}d" "${ZONE_FILE}" | /usr/bin/grep "^${JAIL_NAME}"`

if [ -z "${EXISTING_DNS_ENTRY}" ]; then
  if [ "${ACTION}" = "register" ]; then
    echo "${JAIL_NAME}    A   ${JAIL_IP}" >>"${ZONE_FILE}"
  fi
else
  if [ "${ACTION}" = "deregister" ]; then
    /usr/bin/sed -i "" "/^${JAIL_NAME} *A *.*/d" "${ZONE_FILE}"
  else
    /usr/bin/sed -i "" "s/^${JAIL_NAME} *A .*/${JAIL_NAME}    A   ${JAIL_IP}/" "${ZONE_FILE}"
  fi
fi
local-unbound-control reload
pfctl -t cbsd -T ${PF_ACTION} ${JAIL_IP}
