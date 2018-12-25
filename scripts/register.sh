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
TEMPLATE=""${PROJECT_ROOT}"/templates/nsupdate-add.txt"
PF_ACTION="add"

if [ "${ACTION}" = "deregister" ]; then
  TEMPLATE=""${PROJECT_ROOT}"/templates/nsupdate-delete.txt"
  PF_ACTION="delete"
fi

if [ "${JAIL_NAME}" != "cbsd" ]; then
  TEMP_FILE=`mktemp ${CBSD_WORKDIR}/jails-data/cbsd-data/tmp/tmp.XXXXXX`
  JAIL_IP_LAST=`echo ${JAIL_IP} | awk -F '.' '{print $4}'`
  REVERSE_ZONE=`echo ${JAIL_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  sed \
    -e "s/JAIL_NAME/${JAIL_NAME}/g" \
    -e "s/JAIL_IP_LAST/${JAIL_IP_LAST}/g" \
    -e "s/JAIL_IP/${JAIL_IP}/g" \
    -e "s/REVERSE_ZONE/${REVERSE_ZONE}/g" \
    -e "s/MASTER_IP/${MASTER_IP}/g" \
    -e "s/DOMAIN/${DOMAIN}/g" \
    ${TEMPLATE} \
    >${TEMP_FILE}

  cbsd jexec jname=cbsd nsupdate -4 -k /usr/local/etc/namedb/cbsd.key ${TEMP_FILE#${CBSD_WORKDIR}/jails-data/cbsd-data}
  rm -rf ${TEMP_FILE}
fi
pfctl -t cbsd -T ${PF_ACTION} ${JAIL_IP}
