#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
USER="${1}"
SERVICE="${2}"
FILE="${3}"
UID="${4}"
GID="${5}"
TEMP_FILE=`mktemp`
FILE_NAME=`basename ${FILE}`

. "${SCRIPT_DIR}/default.conf"

trap "rm -rf ${TEMP_FILE}" HUP INT ABRT BUS TERM  EXIT


help() {
  echo "Usage: $0 <user> <service> <file> <uid> <gid>"
}


if [ -z "${USER}" -o -z "${SERVICE}" -o -z "${FILE}" -o -z "${UID}" -o -z "${GID}" ]; then
  help >&2
  exit 1
fi


sed \
  -e "s:DOMAIN:${DOMAIN}:g" \
  -e "s:VM_INTERFACE_IP:${VM_INTERFACE_IP}:g" \
  -e "s:MASTER_IP:${MASTER_IP}:g" \
  -e "s:SERVICE:${SERVICE}:g" \
  -e "s:UID:${UID}:g" \
  -e "s:GID:${GID}:g" \
  "${FILE}" >"${TEMP_FILE}"

IP=`reggae get-ip ${SERVICE}`
scp -i "${PROJECT_ROOT}/id_rsa" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ${TEMP_FILE} ${USER}@${IP}:${FILE_NAME}
