#!/bin/sh

set -e

BACKEND=$(reggae get-config BACKEND)
SERVICE="${1}"
TYPE="${2}"
JAIL_PATH=$(jls -j ${SERVICE} path)

cleanup() {
  umount "${JAIL_PATH}/root/shell"
}

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail> <type>" 2>&1
  exit 1
fi

trap "cleanup" HUP INT ABRT BUS TERM  EXIT

if [ "${TYPE}" = "jail" ]; then
  mkdir "${JAIL_PATH}/root/shell" >/dev/null 2>&1 || true
  mount_nullfs "${PWD}/shell" "${JAIL_PATH}/root/shell"
  reggae jexec ${SERVICE} /root/shell/provision.sh
elif [ "${TYPE}" = "bhyve" ]; then
  reggae scp provision ${SERVICE} shell
  env VERBOSE="yes" reggae ssh provision ${SERVICE} mdo shell/provision.sh
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
