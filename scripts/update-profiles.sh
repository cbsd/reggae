#!/bin/sh

set -e

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
PROJECT_DIR="${SCRIPT_DIR}/.."
. "${SCRIPT_DIR}/default.conf"

RSYNC_CMD="rsync --recursive --verbose --progress --delete-after"


echo ${RSYNC_CMD} ${PROJECT_DIR}/cbsd-profile/system/ ${CBSD_WORKDIR}/share/jail-system-reggae/
${RSYNC_CMD} ${PROJECT_DIR}/cbsd-profile/system/ ${CBSD_WORKDIR}/share/jail-system-reggae/
echo ${RSYNC_CMD} ${PROJECT_DIR}/cbsd-profile/skel/ ${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel/
${RSYNC_CMD} ${PROJECT_DIR}/cbsd-profile/skel/ ${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel/
echo cp ${PROJECT_DIR}/cbsd-profile/jail-freebsd-reggae.conf ${CBSD_WORKDIR}/etc/defaults/
cp ${PROJECT_DIR}/cbsd-profile/jail-freebsd-reggae.conf ${CBSD_WORKDIR}/etc/defaults/
