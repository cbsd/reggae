#!/bin/sh

export INET=$1
export ACTION=$2
export IP=$3
export NAME=`/bin/echo $4 | /usr/bin/cut -f 1 -d '.'`
export DOMAIN=$5
export SOCKET="/var/run/reggae/reggae.sock"
export ZONE_FILE="/usr/local/etc/nsd/zones/master/${DOMAIN}"


expand_address() {
  ip=$1
  double_color_exists=`echo ${ip} | grep -o '::'`
  if [ -z "${double_color_exists}" ]; then
    echo "${ip}"
    return
  fi
  part_number=`echo "${ip}" | sed 's/:/ /g' | wc -w | xargs`
  zero_number=`echo "8 - ${part_number}" | bc`
  double_colon_removed=`echo "${ip}" | sed 's/::/ /g'`
  first_part=`echo "${double_colon_removed}" | cut -f 1 -d ' '`
  last_part=`echo "${double_colon_removed}" | cut -f 2 -d ' '`
  address=""
  for part in $(echo "${first_part}" | sed 's/:/ /g'); do
    address="${address}:${part}"
  done

  if [ "${zero_number}" != "0" ]; then
    for zeros in $(seq 1 ${zero_number}); do
      address="${address}:0000"
    done
  fi

  for part in $(echo "${last_part}" | sed 's/:/ /g'); do
    address="${address}:${part}"
  done
  echo $address | cut -b 2-
}


reverse_address() {
  rev_address=""
  address=$1
  for part in $(echo "${address}" | sed 's/:/ /g'); do
    part_length=`echo "${part}" | wc -c | xargs`
    zero_length=`echo "5 - ${part_length}" | bc`
    if [ "${zero_length}" != "0" ]; then
      for zero in $(seq 1 ${zero_length}); do
        rev_address="${rev_address}0"
      done
    fi
    rev_address="${rev_address}${part}"
  done
  echo "${rev_address}" | rev
}


get_zone() {
  zone=""
  address=`expand_address "${1}"`
  rev_address=`reverse_address ${address}`
  for char in $(echo ${rev_address} | grep -o .); do
    zone="${zone}${char}."
  done
  echo ${zone}ip6.arpa | cut -b 33-
}


get_ptr() {
  ptr=""
  address=`expand_address "${1}"`
  rev_address=`reverse_address ${address}`
  for char in $(echo ${rev_address} | grep -o .); do
    ptr="${ptr}${char}."
  done
  echo ${ptr} | cut -b 1-31
}


create_zone() {
  cat <<EOF >"${ZONE_FILE}"
${DOMAIN}. SOA ${DOMAIN}. hostmaster.DOMAIN. (
                  1998092901  ; Serial number
                  60          ; Refresh
                  1800        ; Retry
                  3600        ; Expire
                  1728 )      ; Minimum TTL
${DOMAIN}.            NS      ${DOMAIN}.

\$ORIGIN ${DOMAIN}.
EOF

  cat <<EOF >>"/usr/local/etc/nsd/nsd.conf"

zone:
	name: "${DOMAIN}"
	zonefile: "master/${DOMAIN}"
EOF
}


create_reverse_zone() {
  cat <<EOF >"${REVERSE_ZONE_FILE}"
${REVERSE_ZONE}.	IN SOA	${DOMAIN}. network.${DOMAIN}. (
				46         ; serial
				86400      ; refresh (1 day)
				43200      ; retry (12 hours)
				604800     ; expire (1 week)
				10800      ; minimum (3 hours)
				)
			IN NS	network.${DOMAIN}.
\$ORIGIN ${REVERSE_ZONE}.
EOF

  cat <<EOF >>"/usr/local/etc/nsd/nsd.conf"

zone:
	name: "${REVERSE_ZONE}"
	zonefile: "master/${REVERSE_ZONE}"
EOF
}


cleanup() {
  if [ "${INET}" = "ipv4" ]; then
    export RECORD="A"
  elif [ "${INET}" = "ipv6" ]; then
    export RECORD="AAAA"
  fi
  /usr/bin/sed -i "" "/^.* *${RECORD} *${IP}$/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${NAME} *${RECORD} /d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${IP_REVERSE} *PTR *.*/d" "${REVERSE_ZONE_FILE}"
  /usr/bin/sed -i "" "/^.* *PTR *${NAME}.${DOMAIN}/d" "${REVERSE_ZONE_FILE}"
}


alter_host() {
  if [ "${INET}" = "ipv4" ]; then
    if [ "${ACTION}" = "add" ]; then
      if [ ! -z "${NAME}" ]; then
        /bin/echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
        if [ "${NAME}" = "@" ]; then
          /bin/echo "${IP_REVERSE}    PTR   ${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        else
          /bin/echo "${IP_REVERSE}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        fi
      fi
      /bin/echo "register ipv4 ${IP} ${NAME}${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    elif [ "${ACTION}" = "delete" ]; then
      /bin/echo "unregister ipv4 ${IP} ${NAME}${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    fi
  elif [ "${INET}" = "ipv6" ]; then
    if [ "${ACTION}" = "add" ]; then
      if [ ! -z "${NAME}" ]; then
        /bin/echo "${NAME}    AAAA   ${IP}" >>"${ZONE_FILE}"
        if [ "${NAME}" = "@" ]; then
          /bin/echo "${IP_REVERSE}    PTR   ${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        else
          /bin/echo "${IP_REVERSE}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        fi
      fi
      /bin/echo "register ipv6 ${IP} ${NAME}${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    elif [ "${ACTION}" = "delete" ]; then
      /bin/echo "unregister ipv6 ${IP} ${NAME}${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    fi
  fi
}


if [ "${INET}" = "ipv4" ]; then
  export REVERSE_ZONE=`/bin/echo ${IP} | /usr/bin/awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
elif [ "${INET}" = "ipv6" ]; then
  export REVERSE_ZONE=`get_zone ${IP}`
fi
export REVERSE_ZONE_FILE="/usr/local/etc/nsd/zones/master/${REVERSE_ZONE}"


if [ "${INET}" = "ipv4" ]; then
  export IP_REVERSE=`/bin/echo "${IP}" | /usr/bin/awk -F '.' '{print $4}'`
elif [ "${INET}" = "ipv6" ]; then
  export IP_REVERSE=`get_ptr ${IP}`
fi


if [ ! -e "${ZONE_FILE}" ]; then
  create_zone
  /usr/local/bin/sudo /usr/sbin/service nsd restart
fi

if [ ! -e "${REVERSE_ZONE_FILE}" ]; then
  create_reverse_zone
  /usr/local/bin/sudo /usr/sbin/service nsd restart
fi


cleanup
alter_host

/usr/local/bin/sudo /usr/local/sbin/nsd-control reload ${DOMAIN}
/usr/local/bin/sudo /usr/local/sbin/nsd-control reload ${REVERSE_ZONE}
