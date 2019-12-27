#!/bin/sh


SERVER="${1}"
DIRECTORY="${2}"
MOUNTPOINT="${3}"
EXTRA_SCRIPT="${4}"

if [ $# -lt 3 ]; then
  echo "${0} <server> <directory> <mountpoint>" >&2
  exit 1
fi


if [ ! -e "${MOUNTPOINT}/Makefile" ]; then
  mount "${SERVER}:${DIRECTORY}" "${MOUNTPOINT}"
  if [ ! -z "${EXTRA_SCRIPT}" ]; then
    EXTRA_SCRIPT_ABS="/usr/local/bin/`basename ${EXTRA_SCRIPT}`"
    sh "${EXTRA_SCRIPT_ABS}"
  fi
fi
