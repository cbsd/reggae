#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
SERVICE="${1}"
shift

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail>" 2>&1
  exit 1
fi

TEMP_DIR=`mktemp -d ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/tmp/tmp.XXXXXX`
TEMP_DIR_JAILED=${TEMP_DIR#${CBSD_WORKDIR}/jails-data/${SERVICE}-data}
PLAYBOOK_DIR="${PWD}/playbook"
trap "/bin/rm -rf ${TEMP_DIR}" HUP INT ABRT BUS TERM  EXIT

echo "${PWD}"
cp -rp ${PLAYBOOK_DIR}/* ${TEMP_DIR}/
cbsd jexec "jname=${SERVICE}" ${TEMP_DIR_JAILED}/provision.sh $@
