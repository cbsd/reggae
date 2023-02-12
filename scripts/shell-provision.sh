#!/bin/sh

BACKEND=$(reggae get-config BACKEND)
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
  if [ "${BACKEND}" = "base" ]; then
    BASE_WORKDIR=$(reggae get-config BASE_WORKDIR)
    mkdir ${BASE_WORKDIR}/${SERVICE}/root/shell >/dev/null 2>&1 || true
    mount_nullfs "${PWD}/shell" "${BASE_WORKDIR}/${SERVICE}/root/shell"
  elif [ "${BACKEND}" = "base" ]; then
    CBSD_WORKDIR=$(sysrc -s cbsdd -n cbsd_workdir)
    mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/shell >/dev/null 2>&1 || true
    mount_nullfs "${PWD}/shell" "${CBSD_WORKDIR}/jails/${SERVICE}/root/shell"
  fi
  jexec ${SERVICE} /root/shell/provision.sh
elif [ "${TYPE}" = "bhyve" ]; then
  reggae scp provision ${SERVICE} shell
  env VERBOSE="yes" reggae ssh provision ${SERVICE} sudo shell/provision.sh
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
