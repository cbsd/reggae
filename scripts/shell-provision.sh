#!/bin/sh

CBSD_WORKDIR=`sysrc -s cbsdd -n cbsd_workdir`
SERVICE="${1}"
TYPE="${2}"

cleanup() {
  umount "${CBSD_WORKDIR}/jails/${SERVICE}/root/shell"
}

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail> <type>" 2>&1
  exit 1
fi

if [ "${TYPE}" = "jail" ]; then
  trap "cleanup" HUP INT ABRT BUS TERM  EXIT
  mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/shell >/dev/null 2>&1 || true
  mount_nullfs "${PWD}/shell" "${CBSD_WORKDIR}/jails/${SERVICE}/root/shell"
  cbsd jexec "jname=${SERVICE}" cmd="/root/shell/provision.sh"
elif [ "${TYPE}" = "bhyve" ]; then
  reggae scp provision ${SERVICE} shell
  env VERBOSE="yes" reggae ssh provision ${SERVICE} sudo shell/provision.sh
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
