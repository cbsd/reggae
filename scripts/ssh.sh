#!/bin/sh

set -e

SCRIPT_DIR=$(dirname $0)
PROJECT_ROOT=$(readlink -f ${SCRIPT_DIR}/..)
USER="${1}"
SERVICE="${2}"
shift
shift
IP=${IP:=$(reggae get-ip ${SERVICE})}


help() {
  echo "Usage: $0 <user> <service>"
}


if [ -z "${USER}" -o -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi

ssh_cmd="ssh -t -i ${PROJECT_ROOT}/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${USER}@${IP} ${@}"

if [ "${VERBOSE}" = "yes" ]; then
  echo "ssh_cmd=${ssh_cmd}"
  ${ssh_cmd}
else
  ${ssh_cmd} >/dev/null 2>&1
fi
