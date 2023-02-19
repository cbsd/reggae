#!/bin/sh

IMAGE_PATH="${1}"

if [ -z "${IMAGE_PATH}" ]; then
  echo "Usage: ${0} <image>" >&2
  exit 1
fi

if [ ! -e "${IMAGE_PATH}" ]; then
  echo "${IMAGE_PATH} does not exist" >&2
  exit 1
fi

if [ "$(whoami)" != "root" ]; then
  echo "Root privileges needed" >&2
  exit 1
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/utils.sh"

IMAGE_ABSOLUTE_PATH="$(readlink -f "${IMAGE_PATH}")"
DOMAIN=$(reggae get-config DOMAIN)
PKG_PROXY=$(reggae get-config PKG_PROXY)
IMAGE=$(basename ${IMAGE_PATH})
JAIL=$(echo ${IMAGE} | sed 's;\.img$;;')
CONFIG="$(getextattr -q system config ${IMAGE_PATH})"

if [ -z "${CONFIG}" ]; then
  HYPERVISOR="${2:-jail}"
  CBSD_WORKDIR=$(sysrc -s cbsdd -n cbsd_workdir)

  trap "rm -rf ${CBSD_WORKDIR}/import/${IMAGE}" HUP INT ABRT BUS TERM  EXIT

  cp "${IMAGE_PATH}" "${CBSD_WORKDIR}/import/${IMAGE}"
  if [ "${HYPERVISOR}" = "jail" ]; then
    cbsd jimport "${JAIL}"
    cbsd jset jname=${JAIL} host_hostname=${JAIL}.${DOMAIN}
    if [ "${PKG_PROXY}" != "no" ]; then
      sed -i "" \
        -e "s;pkg_env : { http_proxy: \".*\" };pkg_env : { http_proxy: \"http://${PKG_PROXY}\" };g" \
        ${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf
      written=$(grep -o '^pkg_env :' ${CBSD_WORKDIR}/jails-data/${JAIL}-data/usr/local/etc/pkg.conf)
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
else
  ID=$(next_id)
  JAIL_CONFIG="$(echo ${CONFIG} | sed -e "s/\$id = [[:digit:]]*;/\$id = ${ID};/")"
  USE_ZFS=$(reggae get-config USE_ZFS)
  ZFS_POOL=$(reggae get-config ZFS_POOL)
  BASE_WORKDIR=$(reggae get-config BASE_WORKDIR)

  check "${JAIL}" "${BASE_WORKDIR}/${JAIL}"

  if [ "${USE_ZFS}" = "yes" ]; then
    zfs create -p "${ZFS_POOL}${BASE_WORKDIR}/${JAIL}"
  else
    mkdir -p "${BASE_WORKDIR}/${JAIL}"
  fi
  tar -x -p -f "${IMAGE_PATH}" --cd "${BASE_WORKDIR}/${JAIL}"
  echo "${JAIL_CONFIG}" >>/etc/jail.conf
fi
