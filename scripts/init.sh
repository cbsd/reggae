#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"


PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
MAKEFILE="Makefile"
PROVISIONER="${1}"
SERVICE_NAME=`basename ${PWD}`

if [ ! -z "${PROVISIONER}" ]; then
  MAKEFILE="${MAKEFILE}.${PROVISIONER}"
else
  MAKEFILE="${MAKEFILE}.default"
fi

echo -n "Generating Makefile ... "
sed -e "s;SERVICE_NAME;${SERVICE_NAME};g" "${PROJECT_ROOT}/templates/${MAKEFILE}" >Makefile
echo "done"


echo -n "Generating .gitignore ... "
cp "${PROJECT_ROOT}/templates/gitignore" .gitignore
echo "done"

if [ -d "${PROJECT_ROOT}"/skel/${PROVISIONER} ]; then
  echo -n "Populating from skel for ${PROVISIONER} ... "
  cp -r "${PROJECT_ROOT}"/skel/${PROVISIONER}/* .
  echo "done"
fi
