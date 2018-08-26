#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
SERVICE="${1}"
TYPE="${2}"
TEMP_DIR=`mktemp -d ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/tmp/tmp.XXXXXX`
TEMP_DIR_JAILED=${TEMP_DIR#${CBSD_WORKDIR}/jails-data/${SERVICE}-data}

init() {
  mount_nullfs "${PWD}/shell" "${CBSD_WORKDIR}/jails/${SERVICE}/root/shell"
}

cleanup() {
  umount "${CBSD_WORKDIR}/jails/${SERVICE}/root/shell"
}

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail> <type>" 2>&1
  exit 1
fi

if [ "${TYPE}" = "jail" ]; then
  trap "cleanup" HUP INT ABRT BUS TERM  EXIT
  init
  cbsd jexec "jname=${SERVICE}" /root/shell/provision.sh
elif [ "${TYPE}" = "bhyve" ]; then
  reggae ssh provision ${SERVICE} /usr/src/shell/provision.sh
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
