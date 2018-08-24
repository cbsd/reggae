#!/bin/sh

SERVICE="${1}"
MAC_FILE="/tmp/${SERVICE}"


help() {
  echo "Usage: $0 <service>"
}


get_ip() {
  MAC=`cat ${MAC_FILE}`
  IP=""
  while [ -z ${IP} ]; do
    IP=`cbsd jexec jname=dhcp ip-by-mac.sh ${MAC}`
  done
  echo ${IP}
}


if [ -z "${SERVICE}" ]; then
  help >&2
  exit 1
fi


if [ ! -e "${MAC_FILE}" ]; then
  echo "${MAC_FILE} does not exist" >&2
  exit 1
fi


get_ip
