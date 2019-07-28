#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

ALL=${1}
SCRIPT_DIR=`dirname $0`
PROJECT_DIR="${SCRIPT_DIR}/.."
. "${SCRIPT_DIR}/default.conf"

ON_JAILS=""
ON_JAILS_RAW=`env NOCOLOR=1 cbsd jls header=0 display=status,jname | grep '^On '`

skip="YES"
for item in ${ON_JAILS_RAW}; do
  if [ "${skip}" = "YES" ]; then
    skip="NO"
  else
    skip="YES"
    ON_JAILS="${ON_JAILS} ${item}"
  fi
done

for jname in ${ON_JAILS}; do
  echo "=== ${jname} ===="
  cbsd jexec "jname=${jname}" pkg upgrade
  cbsd jexec "jname=${jname}" pkg autoremove -y
  cbsd jexec "jname=${jname}" pkg clean -y
  echo
done

if [ "${ALL}" = "all" ]; then
  OFF_JAILS=""
  OFF_JAILS_RAW=`env NOCOLOR=1 cbsd jls header=0 display=status,jname | grep '^Off '`

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
