#!/bin/sh

SOCKET_DIR=${1}
if [ -z "${SOCKET_DIR}" ]; then
  echo "Usage: $0 <directory to put socket in>" >&2
  exit 1
fi
SOCKET="${SOCKET_DIR}/reggae.sock"
trap "rm -rf ${SOCKET}" HUP INT ABRT BUS TERM  EXIT

rm -rf "${SOCKET}"


register_v4() {
  pfctl -t cbsd -T add $1
}


register_v6() {
  pfctl -t cbsd6 -T add $1
}


deregister_v4() {
  pfctl -t cbsd -T delete $1
}


deregister_v6() {
  pfctl -t cbsd6 -T delete $1
}


/usr/bin/nc -k -l -U "${SOCKET}" | while read action inet ip; do
  echo "action = ${action}, inet = ${inet}, ip = ${ip}"
  if [ "${action}" = "register" ]; then
    if [ "${inet}" = "ipv4" ]; then
      register_v4 ${ip}
    elif [ "${inet}" = "ipv6" ]; then
      register_v6 ${ip}
    fi
  elif [ "${action}" = "deregister" ]; then
    if [ "${inet}" = "ipv4" ]; then
      deregister_v4 ${ip}
    elif [ "${inet}" = "ipv6" ]; then
      deregister_v6 ${ip}
    fi
  fi
done
