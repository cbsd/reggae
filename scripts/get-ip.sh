#!/bin/sh

SERVICE="${1}"


help() {
  echo "Usage: $0 <service>"
}


get_ip() {
  bhyve_conf="/usr/cbsd/jails-system/${SERVICE}/bhyve.conf"
  . "${bhyve_conf}"
  HWADDR=`echo $nic_args | grep --color=auto -o 'mac=..:..:..:..:..:..' | cut -f 2 -d '='`
  IP=""
  while [ -z ${IP} ]; do
    IP=`cbsd jexec jname=network cmd="ip-by-mac.sh ${HWADDR}"`
  done
  echo ${IP}
}


if [ -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi


get_ip
