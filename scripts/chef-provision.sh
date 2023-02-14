#!/bin/sh

SERVICE="${1}"
TYPE="${2}"

if [ -z "${SERVICE}" ]; then
  echo "Usage: ${0} <jail>" 2>&1
  exit 1
fi

JAIL_PATH=$(jls -j ${SERVICE} path)


init() {
  if [ "${TYPE}" = "jail" ]; then
    reggae jexec ${SERVICE} pkg install -y rubygem-chef
    mkdir ${JAIL_PATH}/etc/chef >/dev/null 2>&1 || true
    mkdir ${JAIL_PATH}/root/chef >/dev/null 2>&1 || true
    mount_nullfs "${PWD}/chef" "${JAIL_PATH}/root/chef"
  elif [ "${TYPE}" = "bhyve" ]; then
    reggae ssh provision ${SERVICE} sudo mkdir /etc/chef >/dev/null 2>&1 || true
    reggae ssh provision ${SERVICE} sudo pkg install -y rubygem-chef
  fi
}

cleanup() {
  if [ "${TYPE}" = "jail" ]; then
    rm -rf "${JAIL_PATH}/root/chef/nodes"
    umount "${JAIL_PATH}/root/chef"
  elif [ "${TYPE}" = "bhyve" ]; then
    reggae ssh provision ${SERVICE} sudo rm -rf /usr/src/chef/nodes
  fi
}

trap "cleanup" HUP INT ABRT BUS TERM  EXIT
init

if [ "${TYPE}" = "jail" ]; then
  reggae jexec ${SERVICE} "cd /root/chef && chef-client --local-mode --override-runlist core"
elif [ "${TYPE}" = "bhyve" ]; then
	reggae ssh provision ${SERVICE} "cd /usr/src/chef && sudo chef-client --local-mode --override-runlist core"
else
  echo "Type ${TYPE} unknown!" >&2
  exit 1
fi
