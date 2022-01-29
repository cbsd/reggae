#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
LOCK_DIR="${CBSD_WORKDIR}/tmp"
LOCK_FILE="${LOCK_DIR}/cbsd.zone.lock"

if [ -d "${LOCK_DIR}" ]; then
  lockf ${LOCK_FILE} reggae register
else
  reggae register
fi
