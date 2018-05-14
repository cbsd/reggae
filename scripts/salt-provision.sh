#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
SERVICE="${1}"
shift

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail>" 2>&1
  exit 1
fi

PLAYBOOK_DIR="${PWD}/playbook"

init() {
  mount_nullfs "${PWD}/playbook" "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states"
  echo 'file_client: local' >"${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d/reggae.conf"
}

cleanup() {
  rm -rf "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d/reggae.conf"
  umount "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states"
}

trap "cleanup" HUP INT ABRT BUS TERM  EXIT

init
cbsd jexec "jname=${SERVICE}" 'salt-call --local state.apply'
