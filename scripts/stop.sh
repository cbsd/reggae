#!/bin/sh

set -e


help() {
  echo "Usage: ${0} <jail name>"
}


SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/utils.sh"

JNAME="${1}"
if [ -z "${JNAME}" ]; then
  help >&2
  exit 1
fi

BACKEND=$(get_backend)


if [ "${BACKEND}" = "base" ]; then
  service jail stop "${JNAME}"
elif [ "${BACKEND}" = "cbsd" ]; then
  cbsd jstop "${JNAME}"
fi
