#!/bin/sh

set -e

NAME="${1}"
if [ -z "${NAME}" ]; then
  echo "Usage: $0 <jail>" >&2
  exit 1
fi
BASE=$(reggae get-config BASE_WORKDIR)
POOL=$(reggae get-config ZFS_POOL)
USE_ZFS=$(reggae get-config USE_ZFS)


service jail stop "${NAME}"
sysrc -s jail jail_list-="${NAME}"
if [ -e "${BASE}/${NAME}" ]; then
  if [ "${USE_ZFS}" = "yes" ]; then
    zfs destroy -f "${POOL}${BASE}/${NAME}"
  else
    rm -rf "${BASE}/${NAME}"
  fi
fi
rm -f "/etc/jail.conf.d/${NAME}.conf"
