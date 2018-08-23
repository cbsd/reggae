#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
COMMIT_FILE="${CBSD_WORKDIR}/jails-data/dhcp-data/tmp/commit.txt"
IP=
SERVICE="${1}"
DOMAIN="${2}"
SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`


help() {
  echo "Usage: $0 <service> <domain>"
}


if [ -z "${SERVICE}" -o -z "${DOMAIN}" ]; then
  help >&2
  exit 1
fi


cleanup() {
  rm -f "${COMMIT_FILE}"
}

trap "cleanup" HUP INT ABRT BUS TERM  EXIT

echo "Waiting for commit file to appear"
EXIT_STATUS=1
while [ "${EXIT_STATUS}" != "0" ]; do
  if [ -e "${COMMIT_FILE}" ]; then
    IP=`cut -d ' ' -f 1 ${COMMIT_FILE}`
    EXIT_STATUS=0
  else
    sleep 1
  fi
done


echo "Got IP ${IP}"
EXIT_STATUS=1
while [ "${EXIT_STATUS}" != "0" ]; do
  sleep 1
	ssh -i "${PROJECT_ROOT}/id_rsa" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" provision@${IP} "sudo sysrc hostname=${SERVICE}.${DOMAIN}"
  EXIT_STATUS=$?
done
