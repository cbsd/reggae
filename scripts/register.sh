#!/bin/sh


PROJECT_ROOT=`dirname $0`
PROJECT_PATH=`readlink -f ${PROJECT_ROOT}/..`

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi
. "${PROJECT_PATH}/scripts/default.conf"

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
JAIL_NAME=${jname}
JAIL_IP=`echo ${ip4_addr} | cut -f 1 -d '/'`
ACTION="${1}"
TEMPLATE="/usr/local/share/reggae/templates/nsupdate-add.txt"
PF_ACTION="add"

if [ "${ACTION}" = "deregister" ]; then
    TEMPLATE="/usr/local/share/reggae/templates/nsupdate-delete.txt"
    PF_ACTION="delete"
fi

if [ "${JAIL_NAME}" != "resolver" ]; then
  TEMP_FILE=`mktemp ${CBSD_WORKDIR}/jails-data/resolver-data/tmp/tmp.XXXXXX`
  sed \
      -e "s/JAIL_NAME/${JAIL_NAME}/g" \
      -e "s/JAIL_IP/${JAIL_IP}/g" \
      -e "s/RESOLVER_IP/${RESOLVER_IP}/g" \
      ${TEMPLATE} \
      >${TEMP_FILE}

  cbsd jexec jname=resolver nsupdate -k /usr/local/etc/namedb/cbsd.key ${TEMP_FILE#${CBSD_WORKDIR}/jails-data/resolver-data}
  rm -rf ${TEMP_FILE}
fi
pfctl -t cbsd -T ${PF_ACTION} ${JAIL_IP}

