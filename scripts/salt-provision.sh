#!/bin/sh

CBSD_WORKDIR=`sysrc -s cbsdd -n cbsd_workdir`
SERVICE="${1}"
TYPE="${2}"
PY_VERSION_MAJOR="3"
PY_VERSION_MINOR="8"
PY_PREFIX="py${PY_VERSION_MAJOR}${PY_VERSION_MINOR}"

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail>" 2>&1
  exit 1
fi

init() {
  if [ "${TYPE}" = "jail" ]; then
    jexec ${SERVICE} pkg install -y ${PY_PREFIX}-salt
    mkdir -p ${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d >/dev/null 2>&1 || true
    mkdir -p ${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states >/dev/null 2>&1 || true
    mount_nullfs "${PWD}/salt/states" "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states"
    echo 'file_client: local' >"${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d/reggae.conf"
  elif [ "${TYPE}" = "bhyve" ]; then
    reggae ssh provision ${SERVICE} sudo pkg install -y "${PY_PREFIX}-salt"
    reggae ssh provision ${SERVICE} sudo mkdir -p /usr/local/etc/salt/minion.d >/dev/null 2>&1 || true
    reggae ssh provision ${SERVICE} sudo mkdir -p /usr/local/etc/salt/states >/dev/null 2>&1 || true
    reggae ssh provision ${SERVICE} sudo mount_nullfs /usr/src/salt/states /usr/local/etc/salt/states
    reggae ssh provision ${SERVICE} 'echo file_client: local >reggae.conf'
    reggae ssh provision ${SERVICE} sudo mv reggae.conf /usr/local/etc/salt/minion.d/
  fi
}

cleanup() {
  if [ "${TYPE}" = "jail" ]; then
    rm -rf "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d/reggae.conf"
    umount "${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states"
  elif [ "${TYPE}" = "bhyve" ]; then
    reggae ssh provision ${SERVICE} sudo rm -rf /usr/local/etc/salt/minion.d/reggae.conf
    reggae ssh provision ${SERVICE} sudo umount /usr/local/etc/salt/states
  fi
}

trap "cleanup" HUP INT ABRT BUS TERM  EXIT
init

if [ "${TYPE}" = "jail" ]; then
  jexec ${SERVICE} salt-call --local state.apply
elif [ "${TYPE}" = "bhyve" ]; then
  reggae ssh provision ${SERVICE} sudo salt-call --local state.apply
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
