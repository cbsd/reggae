#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
CLONED_INTERFACES=`sysrc -n cloned_interfaces`
NATIP=`netstat -rn4 | awk '/^default/{print $2}'`
EGRESS=`netstat -rn4 | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
IPV6_PREFIX=`reggae get-config IPV6_PREFIX`
STATIC=NO
MASTER_IP=`reggae get-config MASTER_IP`
NETWORK=`echo ${MASTER_IP} | awk -F '.' '{print $1 "." $2 "." $3 ".0/24"}'`


if [ -z "${DHCP_CONFIG}" ]; then
  STATIC=YES
fi


check_config() {
  if [ -z "${PROJECTS_DIR}" ]; then
    echo "PROJECTS_DIR must be set in /usr/local/etc/reggae.conf" >&2
    exit 1
  fi
  if [ `hostname` = `hostname -s` ]; then
    echo "Hostname must be FQDN. Please set hostname to something like 'myhost.example.com'" >&2
    exit 1
  fi
}


network() {
  interface_config="inet ${INTERFACE_IP} netmask 255.255.255.0 description ${EGRESS}"
  interface_alias_config="inet ${JAIL_INTERFACE_IP} netmask 255.255.255.0"
  interface_ipv6_config="inet6 -ifdisabled auto_linklocal ${IPV6_PREFIX}:1"
  sysctl net.inet.ip.forwarding=1
  sysctl net.inet6.ip6.forwarding=1
  sysrc gateway_enable="YES"
  sysrc ipv6_gateway_enable="YES"
  sysrc cloned_interfaces+="bridge0"
  sysrc ifconfig_bridge0_name="${INTERFACE}"
  sysrc ifconfig_${INTERFACE}="${interface_config}"
  sysrc ifconfig_${INTERFACE}_alias0="${interface_alias_config}"
  sysrc ifconfig_${INTERFACE}_ipv6="${interface_ipv6_config}"
  service netif cloneup
  sleep 1
  ifconfig ${INTERFACE} ${interface_config}
  ifconfig ${INTERFACE} ${interface_alias_config} alias
  ifconfig ${INTERFACE} ${interface_ipv6_config}
}


pf() {
  if [ ! -e /etc/pf.conf ]; then
    sed \
      -e "s:EGRESS:${EGRESS}:g" \
      -e "s:JAIL_INTERFACE_IP:${JAIL_INTERFACE_IP}:g" \
      -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
      -e "s:INTERFACE:${INTERFACE}:g" \
      -e "s:MASTER_IP:${MASTER_IP}:g" \
      "${SCRIPT_DIR}/../templates/pf.conf" >/etc/pf.conf
  fi
  sysrc pflog_enable="YES"
  sysrc pf_enable="YES"
  sysrc blacklistd_enable="YES"
  sysrc sshd_flags+="\-oUseBlacklist=yes"
}


setup_hostname() {
    if [ "${HOSTNAME}" == "${SHORT_HOSTNAME}" ]; then
        HOSTNAME="${SHORT_HOSTNAME}.${DOMAIN}"
        hostname ${HOSTNAME}
        sysrc hostname="${HOSTNAME}"
    fi
}


setup_rtadvd() {
  sysrc rtadvd_enable="YES"
  sysrc rtadvd_interfaces="cbsd0"
  sed \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    "${SCRIPT_DIR}/../templates/rtadvd.conf" >/etc/rtadvd.conf
}


setup_nfs() {
  TMP_EXPORTS=`mktemp`
  sysrc mountd_enable="YES"
  sysrc mountd_flags="-r"
  sysrc nfs_server_enable="YES"
  sysrc nfsv4_server_enable="YES"
  sysrc rpcbind_enable="YES"

  if [ -e /etc/exports ]; then
    cp /etc/exports "${TMP_EXPORTS}"
  fi
  echo "${PROJECTS_DIR} -alldirs -network ${INTERFACE_IP} -mask 255.255.255.0" -maproot=root >>"${TMP_EXPORTS}"
  sort "${TMP_EXPORTS}" | uniq > /etc/exports

  service rpcbind start
  service nfsd start
  service mountd start
  rm "${TMP_EXPORTS}"
}


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

setup_unbound() {
  REVERSE_ZONE=`echo ${INTERFACE_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  REVERSEV6=`get_zone ${IPV6_PREFIX}:1`

  sysrc local_unbound_enable="YES"
  sysrc local_unbound_tls="NO"
  fetch -o /var/unbound/root.hints https://www.internic.net/domain/named.cache
  service local_unbound restart
  sed \
    -e "s:JAIL_INTERFACE_IP:${JAIL_INTERFACE_IP}:g" \
    -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
    "${SCRIPT_DIR}/../templates/unbound.conf" >/var/unbound/unbound.conf
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    -e "s;REVERSEV6;${REVERSEV6};g" \
    -e "s:REVERSE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/unbound_cbsd.conf" >/var/unbound/cbsd.conf
  cp "${SCRIPT_DIR}/../templates/unbound_control.conf" /var/unbound/control.conf
  cp "${SCRIPT_DIR}/../templates/resolvconf.conf" /etc/resolvconf.conf

  chown -R unbound:unbound /var/unbound
  service local_unbound restart
  resolvconf -u
}


check_config
network
pf
setup_hostname
setup_rtadvd
setup_nfs
setup_unbound
