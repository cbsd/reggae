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
  mount_nullfs "${PWD}/chef" "${CBSD_WORKDIR}/jails/${SERVICE}/root/chef"
}

cleanup() {
  umount "${CBSD_WORKDIR}/jails/${SERVICE}/root/chef"
}

trap "cleanup" HUP INT ABRT BUS TERM  EXIT

init
cbsd jexec "jname=${SERVICE}" 'cd /root/chef && chef-client --local-mode --override-runlist core'
