#!/bin/sh

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
SERVICE="${1}"
shift
COMMAND="${@}"
COMMAND="${COMMAND:=true}"
SSH_USER=${SSH_USER:=provision}

help() {
  echo "Usage: $0 <service>"
}


wait_ssh() {
  if [ -z "${1}" ]; then
    echo "Usage: $0 <IP>" >&2
    exit 1
  fi
  EXIT_STATUS=1
  while [ "${EXIT_STATUS}" != "0" ]; do
    reggae ssh ${SSH_USER} ${1} "${COMMAND}"
    EXIT_STATUS=$?
    if [ "${EXIT_STATUS}" != "0" ]; then
      sleep 1
    fi
  done
}


if [ -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi


wait_ssh "${SERVICE}"
