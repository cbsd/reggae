#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
USER="${1}"
SERVICE="${2}"
FILE="${3}"

help() {
  echo "Usage: $0 <user> <service> <file>"
}


if [ -z "${USER}" -o -z "${SERVICE}" -o -z "${FILE}" ]; then
  help >&2
  exit 1
fi


IP=${IP:=`reggae get-ip ${SERVICE}`}
scp -i "${PROJECT_ROOT}/id_rsa" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ${FILE} ${USER}@${IP}:
