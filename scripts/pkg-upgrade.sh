#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
PROJECT_DIR="${SCRIPT_DIR}/.."
. "${SCRIPT_DIR}/default.conf"


env NOCOLOR=1 cbsd jls header=0 display=jname,status | while read jname status; do
  if [ "${status}" = "On" ]; then
    echo "=== ${jname} ===="
    cbsd jexec "jname=${jname}" pkg upgrade
    cbsd jexec "jname=${jname}" pkg autoremove
    cbsd jexec "jname=${jname}" pkg clean
    echo
  fi
done
