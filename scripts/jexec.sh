#!/bin/sh

help() {
  echo "Usage: ${0} [options] <jail name> <command" >&2
  echo "" >&2
  echo "options:" >&2
  echo "  -U <user>" >&2
  echo "    Jail user to execute command as." >&2
}

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


get_backend() {
  BASE_WORKDIR=$(reggae get-config BASE_WORKDIR)
  CBSD_WORKDIR=$(sysrc -s cbsd -n cbsd_workdir)
  JAIL_PATH=$(jls -j ${JNAME} path)
  if [ "${JAIL_PATH}" = "${BASE_WORKDIR}/${JNAME}" ]; then
    echo "base"
  elif [ "${JAIL_PATH}" = "${CBSD_WORKDIR}/${JNAME}" ]; then
    echo "cbsd"
  else
    echo "Unsupported jail backend" >&2
    exit 1
  fi
}


execute_command() {
  BACKEND=$(get_backend)
  if [ "${BACKEND}" = "base" ]; then
    jexec -U "${JAIL_USER}" "${JNAME}" ${COMMAND}
  elif [ "${BACKEND}" = "cbsd" ]; then
    cbsd jexec jname="${JNAME}" user="${JAIL_USER}" cmd="${COMMAND}"
  fi
}


execute_command
