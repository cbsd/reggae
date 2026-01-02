#!/bin/sh


SOCKET=${SOCKET:="/var/run/reggae/reggae.sock"}
ZONE_ROOT=${ZONE_ROOT:="/usr/local/etc/nsd/zones/master"}


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
  INET="${1}"
  IP="${2}"
  if [ "${INET}" = "ipv4" ]; then
    echo ${IP} | /usr/bin/awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'
  elif [ "${INET}" = "ipv6" ]; then
    zone=""
    address=`expand_address "${IP}"`
    rev_address=`reverse_address ${address}`
    for char in $(echo ${rev_address} | grep -o .); do
      zone="${zone}${char}."
    done
    echo ${zone}ip6.arpa | cut -b 33-
  fi
}


get_ptr() {
  INET="${1}"
  IP="${2}"
  if [ "${INET}" = "ipv4" ]; then
    echo "${IP}" | /usr/bin/awk -F '.' '{print $4}'
  elif [ "${INET}" = "ipv6" ]; then
    ptr=""
    address=`expand_address "${IP}"`
    rev_address=`reverse_address ${address}`
    for char in $(echo ${rev_address} | grep -o .); do
      ptr="${ptr}${char}."
    done
    echo ${ptr} | cut -b 1-31
  fi
}


create_zone() {
  DOMAIN="${1}"
  ZONE_FILE="${ZONE_ROOT}/${DOMAIN}"
  if [ ! -e "${ZONE_FILE}" ]; then
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

    /usr/bin/mdo /usr/local/sbin/nsd-control reconfig
  fi
}


create_reverse_zone() {
  INET="${1}"
  IP="${2}"
  DOMAIN="${3}"
  REVERSE_ZONE=`get_zone ${INET} ${IP}`
  REVERSE_ZONE_FILE="${ZONE_ROOT}/${REVERSE_ZONE}"
  if [ ! -e "${REVERSE_ZONE_FILE}" ]; then
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

    /usr/bin/mdo /usr/local/sbin/nsd-control reconfig
  fi
}


cleanup() {
  INET="${1}"
  NAME="${2}"
  IP="${3}"
  DOMAIN="${4}"
  if [ "${INET}" = "ipv4" ]; then
    export RECORD="A"
  elif [ "${INET}" = "ipv6" ]; then
    export RECORD="AAAA"
  fi
  IP_REVERSE=`get_ptr ${INET} ${IP}`
  REVERSE_ZONE=`get_zone ${INET} ${IP}`
  /usr/bin/sed -i "" "/^.* *${RECORD} *${IP}$/d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${NAME} *${RECORD} /d" "${ZONE_FILE}"
  /usr/bin/sed -i "" "/^${IP_REVERSE} *PTR *.*/d" "${REVERSE_ZONE_FILE}"
  /usr/bin/sed -i "" "/^.* *PTR *${NAME}.${DOMAIN}/d" "${REVERSE_ZONE_FILE}"
}


alter_host() {
  INET="${1}"
  ACTION="${2}"
  NAME="${3}"
  IP="${4}"
  DOMAIN="${5}"
  IP_REVERSE=`get_ptr ${INET} ${IP}`
  REVERSE_ZONE=`get_zone ${INET} ${IP}`
  if [ "${INET}" = "ipv4" ]; then
    if [ "${ACTION}" = "add" ]; then
      if [ ! -z "${NAME}" ]; then
        echo "${NAME}    A   ${IP}" >>"${ZONE_FILE}"
        if [ "${NAME}" = "@" ]; then
          echo "${IP_REVERSE}    PTR   ${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        else
          echo "${IP_REVERSE}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        fi
      fi
      echo "register ipv4 ${IP} ${NAME}.${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
  IP_REVERSE="${5}"
    elif [ "${ACTION}" = "delete" ]; then
      echo "unregister ipv4 ${IP} ${NAME}.${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    fi
  elif [ "${INET}" = "ipv6" ]; then
    if [ "${ACTION}" = "add" ]; then
      if [ ! -z "${NAME}" ]; then
        echo "${NAME}    AAAA   ${IP}" >>"${ZONE_FILE}"
        if [ "${NAME}" = "@" ]; then
          echo "${IP_REVERSE}    PTR   ${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        else
          echo "${IP_REVERSE}    PTR   ${NAME}.${DOMAIN}." >>"${REVERSE_ZONE_FILE}"
        fi
      fi
      echo "register ipv6 ${IP} ${NAME}.${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    elif [ "${ACTION}" = "delete" ]; then
      echo "unregister ipv6 ${IP} ${NAME}.${DOMAIN}" | /usr/bin/nc -U "${SOCKET}" -w 0
    fi
  fi
  /usr/bin/mdo /usr/local/sbin/nsd-control reload ${DOMAIN}
  /usr/bin/mdo /usr/local/sbin/nsd-control reload ${REVERSE_ZONE}
  /usr/bin/mdo /usr/sbin/local-unbound-control flush ${NAME}.${DOMAIN}
  /usr/bin/mdo /usr/sbin/local-unbound-control flush ${IP_REVERSE}
}


main() {
  INET="${1}"
  ACTION="${2}"
  IP="${3}"
  NAME="${4}"
  DOMAIN="${5}"

  create_zone "${DOMAIN}"
  create_reverse_zone "${INET}" "${IP}" "${DOMAIN}"
  cleanup "${INET}" "${NAME}" "${IP}" "${DOMAIN}"
  alter_host "${INET}" "${ACTION}" "${NAME}" "${IP}" "${DOMAIN}"
}


if [ "$#" = "5" ]; then
  INET="${1}"
  ACTION="${2}"
  IP="${3}"
  NAME=`echo ${4} | /usr/bin/cut -f 1 -d '.'`
  DOMAIN="${5}"

  main "${INET}" "${ACTION}" "${IP}" "${NAME}" "${DOMAIN}"
elif [ "$#" != "0" ]; then
  echo "Usage: $0 <ipv4/ipv6> <add/delete> <ip> <name> <domain>" >&2
  exit 1
fi
