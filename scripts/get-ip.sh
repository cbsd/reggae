#!/bin/sh

SERVICE="${1}"


help() {
  echo "Usage: $0 <service>"
}


get_ip() {
  . "/usr/cbsd/jails-system/${SERVICE}/rc.conf_${SERVICE}"
  IP=""
  while [ -z ${IP} ]; do
    IP=`cbsd jexec jname=cbsd ip-by-mac.sh ${nic_hwaddr1}`
  done
  echo ${IP}
}


if [ -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi


get_ip
