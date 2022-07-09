#!/bin/sh

ACTION=$1
IP=$2
NAME=`/bin/echo $3 | /usr/bin/cut -f 1 -d '.'`
DOMAIN=$4

SOCKET="/var/run/reggae/reggae.sock"
ZONE_FILE="/usr/local/etc/nsd/zones/master/${DOMAIN}"


/usr/bin/sed -i "" "/^.* *AAAA *${IP}$/d" "${ZONE_FILE}"
/usr/bin/sed -i "" "/^${NAME}    AAAA *.*$/d" "${ZONE_FILE}"


if [ "${ACTION}" = "add" ]; then
  /bin/echo "register ipv6 ${IP}" | /usr/bin/nc -U "${SOCKET}" -w 0
  if [ ! -z "${NAME}" ]; then
    /bin/echo "${NAME}    AAAA   ${IP}" >>"${ZONE_FILE}"
  fi
elif [ "${ACTION}" = "delete" ]; then
  /bin/echo "unregister ipv6 ${IP}" | /usr/bin/nc -U "${SOCKET}" -w 0
fi

/usr/local/bin/sudo /usr/local/sbin/nsd-control reload
