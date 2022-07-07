#!/bin/sh

SOCKET_DIR=${1}
PID_FILE=${2}

if [ -z "${SOCKET_DIR}" -o -z "${PID_FILE}" ]; then
  echo "Usage: $0 <directory to put socket in> <pid file>" >&2
  exit 1
fi

SOCKET="${SOCKET_DIR}/reggae.sock"
MYPID=""



cleanup() {
  pkill -P ${MYPID}
  rm -rf ${SOCKET}
}


trap cleanup HUP INT ABRT BUS TERM  EXIT


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


run() {
  rm -rf "${SOCKET}"
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
}

run &
MYPID=$!
echo $$ >"${PID_FILE}"
wait
