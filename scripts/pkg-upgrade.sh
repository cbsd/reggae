#!/bin/sh

set -e

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

ALL=${1}
SCRIPT_DIR=$(dirname $0)
PROJECT_DIR="${SCRIPT_DIR}/.."
. "${SCRIPT_DIR}/default.conf"


RUNNING_JAILS=""
ALL_RUNNING_JAILS=$(jls host.hostname | cut -f 1 -d '.')

for jname in ${ALL_RUNNING_JAILS}; do
  if [ -f "/etc/jail.conf.d/${jname}.conf" ]; then
    RUNNING_JAILS="${RUNNING_JAILS} ${jname}"
  fi
done

for jname in ${RUNNING_JAILS}; do
  echo "=== ${jname} ===="
  reggae jexec ${jname} pkg upgrade
  reggae jexec ${jname} pkg autoremove -y
  reggae jexec ${jname} pkg clean -y
  echo
done

if [ "${ALL}" = "all" ]; then
  if [ "${BACKEND}" = "base" ]; then
    for jail_version in $(ls -1d "${BASE_WORKDIR}"/*/bin/freebsd-version 2>/dev/null); do
      jail_name=$(echo "${jail_version}" | sed "s;${BASE_WORKDIR}/;;g" | cut -f 1 -d '/')
      skip="NO"
      for running in ${RUNNING_JAILS}; do
        if [ "${jail_name}" = "${running}" ]; then
          skip="YES"
          break
        fi
      done
      if [ "${skip}" = "NO" ]; then
        echo "=== ${jail_name} ==="
        pkg --chroot "${BASE_WORKDIR}/${jail_name}" upgrade
        pkg --chroot "${BASE_WORKDIR}/${jail_name}" autoremove -y
        pkg --chroot "${BASE_WORKDIR}/${jail_name}" clean -y
        echo
      fi
    done
  elif [ "${BACKEND}" = "cbsd" ]; then
    OFF_JAILS=""
    OFF_JAILS_RAW=$(env NOCOLOR=1 cbsd jls header=0 display=status,jname | grep '^Off ')

    skip="YES"
    for item in ${OFF_JAILS_RAW}; do
      if [ "${skip}" = "YES" ]; then
        skip="NO"
      else
        skip="YES"
        OFF_JAILS="${OFF_JAILS} ${item}"
      fi
    done

    for jname in ${OFF_JAILS}; do
      echo "=== ${jname} ===="
      cbsd jstart ${jname}
      cbsd jexec "jname=${jname}" pkg upgrade
      cbsd jexec "jname=${jname}" pkg autoremove -y
      cbsd jexec "jname=${jname}" pkg clean -y
      cbsd jstop ${jname}
      echo
    done
  fi
fi
