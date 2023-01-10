#!/bin/sh

CBSD_WORKDIR=`sysrc -s cbsdd -n cbsd_workdir`
LOCK_DIR="${CBSD_WORKDIR}/tmp"
LOCK_FILE="${LOCK_DIR}/cbsd.zone.lock"

if [ -d "${LOCK_DIR}" ]; then
  lockf ${LOCK_FILE} reggae deregister
else
  reggae deregister
fi
