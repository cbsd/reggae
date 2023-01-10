#!/bin/sh

CBSD_WORKDIR=`sysrc -s cbsdd -n cbsd_workdir`
IMAGE_PATH="${1}"
HYPERVISOR="${2:-jail}"
DOMAIN=`reggae get-config DOMAIN`
PKG_PROXY=`reggae get-config PKG_PROXY`

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
if [ "${HYPERVISOR}" = "jail" ]; then
  cbsd jimport "${JAIL}"
  cbsd jset jname=${JAIL} host_hostname=${JAIL}.${DOMAIN}
  if [ "${PKG_PROXY}" != "no" ]; then
    sed -i "" \
      -e "s;pkg_env : { http_proxy: \".*\" };pkg_env : { http_proxy: \"http://${PKG_PROXY}\" };g" \
      ${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf
    written=`grep -o '^pkg_env :' ${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf`
    if [ -z "${written}" ]; then
      echo "pkg_env : { http_proxy: \"http://${PKG_PROXY}\" }" >>${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf
    fi
  else
    sed -i "" \
      -e "s;pkg_env : { http_proxy: \".*\" };;g" \
      ${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf
  fi
else
  cbsd bimport "${JAIL}"
fi
