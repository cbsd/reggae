#!/bin/sh


SERVER="${1}"
DIRECTORY="${2}"
MOUNTPOINT="${3}"
EXTRA_SCRIPT="${4}"

if [ $# -lt 3 ]; then
  echo "${0} <server> <directory> <mountpoint>" >&2
  exit 1
fi


if [ ! -e /home/devel/.ssh/authorized_keys ]; then
  pw group add devel -g ${GID}
  pw user add devel -u ${UID} -g devel -s /bin/tcsh -G wheel -m
  mkdir -p /home/devel/.ssh
  chmod 700 /home/devel/.ssh
  chpass -p '$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/' devel
  cp /home/provision/id_rsa.pub /home/devel/.ssh/authorized_keys
  chmod 600 /home/devel/.ssh/authorized_keys
  chown -R devel:devel /home/devel
fi


if [ ! -e "${MOUNTPOINT}/Makefile" ]; then
  mount "${SERVER}:${DIRECTORY}" "${MOUNTPOINT}"
  if [ ! -z "${EXTRA_SCRIPT}" ]; then
    EXTRA_SCRIPT_ABS="/usr/local/bin/`basename ${EXTRA_SCRIPT}`"
    sh "${EXTRA_SCRIPT_ABS}"
  fi
fi
