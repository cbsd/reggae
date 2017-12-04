#!/bin/sh


if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
TEMP_FILE=`mktemp ${CBSD_WORKDIR}/jails-data/resolver-data/tmp/tmp.XXXXXX`
JAIL_NAME=${jname}
JAIL_IP=`echo ${ip4_addr} | cut -f 1 -d '/'`
ACTION="${1}"
TEMPLATE="/usr/local/share/reggae/templates/nsupdate-add.txt"

if [ "${ACTION}" = "deregister" ]; then
    TEMPLATE="/usr/local/share/reggae/templates/nsupdate-delete.txt"
fi

sed \
    -e "s/JAIL_NAME/${JAIL_NAME}/g" \
    -e "s/JAIL_IP/${JAIL_IP}/g" \
    ${TEMPLATE} \
    >${TEMP_FILE}

cbsd jexec jname=resolver nsupdate -k /usr/local/etc/namedb/cbsd.key ${TEMP_FILE#${CBSD_WORKDIR}/jails-data/resolver-data}
rm -rf ${TEMP_FILE}

