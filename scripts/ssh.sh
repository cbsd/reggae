#!/bin/sh

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
USER="${1}"
HOST="${2}"
shift
shift


help() {
  echo "Usage: $0 <user> <host|IP>"
}


if [ -z "${USER}" -o -z "${HOST}" ]; then
  help >&2
  exit 1
fi


ssh -i "${PROJECT_ROOT}/id_rsa" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ${USER}@${HOST} ${@}
