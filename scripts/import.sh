#!/bin/sh

CBSD_WORKDIR=`sysrc -n cbsd_workdir`
IMAGE_PATH="${1}"
DOMAIN=`reggae get-config DOMAIN`

if [ -z "${IMAGE_PATH}" ]; then
  echo "Usage: ${0} <image>" 2>&1
  exit 1
fi

if [ ! -e "${IMAGE_PATH}" ]; then
  echo "${IMAGE_PATH} does not exist" 2>&1
  exit 1
fi

IMAGE=`basename ${IMAGE_PATH}`
JAIL=`echo ${IMAGE} | sed 's;\.img$;;'`
trap "rm -rf ${CBSD_WORKDIR}/import/${IMAGE}" HUP INT ABRT BUS TERM  EXIT
cp "${IMAGE_PATH}" "${CBSD_WORKDIR}/import/${IMAGE}"
cbsd jimport "${IMAGE}"
cbsd jset jname=${JAIL} host_hostname=${JAIL}.${DOMAIN}
