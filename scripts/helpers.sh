#!/bin/sh


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
