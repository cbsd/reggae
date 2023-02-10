#!/bin/sh

NAME="${1}"
if [ -z "${NAME}" ]; then
  echo "Usage: $0 <jail>" >&2
  exit 1
fi
BASE=$(reggae get-config BASE_WORKDIR)
POOL=$(reggae get-config ZFS_POOL)
USE_ZFS=$(reggae get-config USE_ZFS)
BSDINSTALL_CHROOT="${BASE}/${NAME}"


service jail stop "${NAME}"
sysrc -s jail jail_list-="${NAME}"
TMPFILE=$(mktemp)
if [ -e "${BSDINSTALL_CHROOT}" ]; then
  if [ "${USE_ZFS}" = "yes" ]; then
    zfs destroy -f "${POOL}${BSDINSTALL_CHROOT}"
  else
    rm -rf "${BSDINSTALL_CHROOT}"
  fi
fi
if [ "${NAME}" = "network" ]; then
  BEGIN=$(grep -n 'network {' /etc/jail.conf | cut -f 1 -d ':')
  END=$(grep -n '^}$' /etc/jail.conf | cut -f 1 -d ':')
  if [ -z "${BEGIN}" -o -z "${END}" ]; then
    echo "No ${NAME} service found in /etc/jail.conf"
  else
    sed -i '' "${BEGIN},${END}d" /etc/jail.conf
  fi
else
  grep -v "^${NAME} " /etc/jail.conf >"${TMPFILE}"
  cat "${TMPFILE}" >/etc/jail.conf
  rm "${TMPFILE}"
fi
