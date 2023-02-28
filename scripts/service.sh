#!/bin/sh

set -e

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
  pfctl -t reggae -T add $1
}


register_v6() {
  pfctl -t reggae6 -T add $1
}


unregister_v4() {
  pfctl -t reggae -T delete $1
}


unregister_v6() {
  pfctl -t reggae6 -T delete $1
}


run() {
  rm -rf "${SOCKET}"
  /usr/bin/nc -k -l -U "${SOCKET}" | while read action inet ip fqdn; do
    if [ "${action}" = "register" ]; then
      if [ "${inet}" = "ipv4" ]; then
        register_v4 ${ip}
      elif [ "${inet}" = "ipv6" ]; then
        register_v6 ${ip}
      fi
    elif [ "${action}" = "unregister" ]; then
      if [ "${inet}" = "ipv4" ]; then
        unregister_v4 ${ip}
      elif [ "${inet}" = "ipv6" ]; then
        unregister_v6 ${ip}
      fi
    fi
    /usr/sbin/local-unbound-control flush ${fqdn}
  done
}

run &
MYPID=$!
echo $$ >"${PID_FILE}"
sleep 0.3
chmod g+w "${SOCKET}"
chown root:216 "${SOCKET}"
wait
