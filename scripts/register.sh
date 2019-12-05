#!/bin/sh

if [ "${vnet}" != "1" ]; then
  SCRIPT_DIR=`dirname $0`
  PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`

  if [ -f "/usr/local/etc/reggae.conf" ]; then
      . "/usr/local/etc/reggae.conf"
  fi
  . "${PROJECT_ROOT}/scripts/default.conf"

  CBSD_WORKDIR=`sysrc -n cbsd_workdir`
  NAME=${jname}
  IP=${ipv4_first}
  ACTION="${1}"
  PF_ACTION="add"
  DOMAIN=`reggae get-config DOMAIN`

  ZONE_FILE="/var/unbound/zones/${DOMAIN}.zone"
  REVERSE_ZONE=`echo ${IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  REVERSE_ZONE_FILE="/var/unbound/zones/${REVERSE_ZONE}.zone"
  LAST_OCTET=`echo "${IP}" | awk -F '.' '{print $4}'`


  if [ "${ACTION}" = "deregister" ]; then
    PF_ACTION="delete"
    pfctl -a "cbsd/${NAME}" -F all >/dev/null 2>&1
    xhost -"${NAME}.${DOMAIN}" >/dev/null 2>&1
  fi

  /usr/bin/sed -i "" "/^.* *A *${IP}$/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${NAME} *A *.*$/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}"

  if [ "${ACTION}" = "register" ]; then
    # Forward
    /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
    /bin/echo "${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
  fi
  local-unbound-control reload
  pfctl -t cbsd -T ${PF_ACTION} ${IP}
fi
