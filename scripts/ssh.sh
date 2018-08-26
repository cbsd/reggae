#!/bin/sh

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
USER="${1}"
SERVICE="${2}"
shift
shift


help() {
  echo "Usage: $0 <user> <service>"
}


if [ -z "${USER}" -o -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi


IP=`reggae get-ip ${SERVICE}`
ssh -t -i "${PROJECT_ROOT}/id_rsa" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ${USER}@${IP} ${@}
