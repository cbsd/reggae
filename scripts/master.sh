#!/bin/sh

SCRIPT_DIR=`dirname $0`
PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
MASTER_DIR="${PROJECT_ROOT}/master"
MASTER="${1}"
MASTER_PROJECT="${MASTER_DIR}/${MASTER}"
MODE=${2:-"prod"}

if [ -z "${MASTER}" ]; then
  echo "Usage: ${0} <master jail> [mode]" 2>&1
  exit 1
fi

if [ ! -d "${MASTER_PROJECT}" ]; then
  echo "No such master jail" 2>&1
  exit 1
fi

TEMP_DIR=`mktemp -d`
trap "/bin/rm -rf ${TEMP_DIR}" HUP INT ABRT BUS TERM  EXIT

cp -r "${MASTER_PROJECT}/"* "${TEMP_DIR}/"
cd "${TEMP_DIR}"
if [ "${MODE}" = "devel" ]; then
  make FOR_DEVEL_MODE=YES
else
  make
fi
