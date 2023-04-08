#!/bin/sh

set -e

help() {
  echo "Usage: ${0} [options] <jail name> <command>"
  echo ""
  echo "options:"
  echo "  -U <user>"
  echo "    Jail user to execute command as."
}


SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/utils.sh"

JAIL_USER="root"
optstring="U:"
args=$(getopt "${optstring}" ${*})
if [ $? -ne 0 ]; then
  help >&2
  exit 1
fi
set -- ${args}
while :; do
  case "${1}" in
    -U)
      JAIL_USER="${2}"
      shift; shift
      ;;
    --)
      shift
      break
    ;;
  esac
done


JNAME="${1}"
shift
COMMAND="${@}"
if [ -z "${JNAME}" -o -z "${COMMAND}" ]; then
  help >&2
  exit 1
fi


execute_command "${JAIL}" "${COMMAND}"
