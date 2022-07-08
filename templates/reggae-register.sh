#!/bin/sh

ACTION=$1
IP=$2
NAME=`/bin/echo $3 | /usr/bin/cut -f 1 -d '.'`
DOMAIN=$4

SOCKET="/var/run/reggae/reggae.sock"
ZONE_FILE="/usr/local/etc/nsd/zones/master/${DOMAIN}"
REVERSE_ZONE=`/bin/echo ${IP} | /usr/bin/awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
REVERSE_ZONE_FILE="/usr/local/etc/nsd/zones/master/${REVERSE_ZONE}"
LAST_OCTET=`/bin/echo "${IP}" | /usr/bin/awk -F '.' '{print $4}'`


/usr/bin/sed -i "" "/^.* *A *${IP}$/d" "${ZONE_FILE}"
/usr/bin/sed -i "" "/^${NAME}    A *.*$/d" "${ZONE_FILE}"
/usr/bin/sed -i "" "/^${LAST_OCTET} *PTR *.*/d" "${REVERSE_ZONE_FILE}"


if [ "${ACTION}" = "add" ]; then
  /bin/echo "register ipv4 ${IP}" | /usr/bin/nc -U "${SOCKET}" -w 0
  if [ ! -z "${NAME}" ]; then
    /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
    /bin/echo "${LAST_OCTET}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
  fi
elif [ "${ACTION}" = "delete" ]; then
  /bin/echo "unregister ipv4 ${IP}" | /usr/bin/nc -U "${SOCKET}" -w 0
fi

/usr/local/bin/sudo /usr/local/sbin/nsd-control reload
