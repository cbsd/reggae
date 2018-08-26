#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
SERVICE="${1}"
TYPE="${2}"

init() {
if [ "${TYPE}" = "jail" ]; then
  mount_nullfs "${PWD}/puppet/manifests" "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/puppet/manifests"
	cbsd jexec "jname=${SERVICE}" pkg install -y puppet5
elif [ "${TYPE}" = "bhyve" ]; then
  reggae ssh provision ${SERVICE} sudo mount_nullfs /usr/src/puppet/manifests /usr/local/etc/puppet/manifests
	reggae ssh provision ${SERVICE} sudo pkg install -y puppet5
fi
}

cleanup() {
if [ "${TYPE}" = "jail" ]; then
  umount "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/puppet/manifests"
elif [ "${TYPE}" = "bhyve" ]; then
  reggae ssh provision ${SERVICE} sudo umount /usr/local/etc/puppet/manifests
fi
}

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail>" 2>&1
  exit 1
fi

trap "cleanup" HUP INT ABRT BUS TERM  EXIT
init

if [ "${TYPE}" = "jail" ]; then
  cbsd jexec "jname=${SERVICE}" 'puppet apply /usr/local/etc/puppet/manifests/site.pp'
elif [ "${TYPE}" = "bhyve" ]; then
  reggae ssh provision ${SERVICE} sudo puppet apply /usr/local/etc/puppet/manifests/site.pp
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
