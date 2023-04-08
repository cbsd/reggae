#!/bin/sh

set -e


next_id() {
  NEXT_ID=$(cat /etc/jail.conf.d/*.conf 2>/dev/null || true | grep -s '$id = ' || true)
  if [ -z "${NEXT_ID}" ]; then
    echo 1
  else
    expr $(cat /etc/jail.conf.d/*.conf | \
      grep '$id' | \
      cut -f 1 -d ';' | \
      awk -F '= ' '{print $2}' | \
      sort -n | \
      tail -n 1 \
    ) + 1
  fi
}


check() {
  NAME="${1}"
  CHROOT="${2}"
  if [ -e "${CHROOT}" ]; then
    echo "${CHROOT} already exists!" >&2
    exit 1
  fi
  if [ -e "/etc/jail.conf.d/${NAME}.conf" ]; then
    echo "${NAME}.conf already defined in /etc/jail.conf.d!" >&2
    exit 1
  fi
}


get_backend() {
  JNAME="${1}"
  BASE_WORKDIR=$(reggae get-config BASE_WORKDIR)
  CBSD_WORKDIR=$(sysrc -s cbsd -n cbsd_workdir 2>/dev/null || true)
  JAIL_PATH=$(jls -j ${JNAME} path)
  if [ "${JAIL_PATH}" = "${BASE_WORKDIR}/${JNAME}" ]; then
    echo "base"
  elif [ ! -z "${CBSD_WORKDIR}" -a "${JAIL_PATH}" = "${CBSD_WORKDIR}/jails/${JNAME}" ]; then
    echo "cbsd"
  else
    echo "Unsupported jail backend" >&2
    exit 1
  fi
}


execute_command() {
  JNAME="${1}"
  COMMAND="${2}"
  BACKEND=$(get_backend "${JNAME}")
  if [ "${BACKEND}" = "base" ]; then
    jexec -U "${JAIL_USER}" "${JNAME}" ${COMMAND}
  elif [ "${BACKEND}" = "cbsd" ]; then
    cbsd jexec jname="${JNAME}" user="${JAIL_USER}" cmd="${COMMAND}"
  fi
}
