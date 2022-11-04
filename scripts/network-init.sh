#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"
. "${SCRIPT_DIR}/../templates/reggae-register.sh"

SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
CLONED_INTERFACES=`sysrc -n cloned_interfaces`
NATIP=`netstat -rn4 | awk '/^default/{print $2}'`
EGRESS=`netstat -rn4 | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS} 2>/dev/null`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
STATIC=NO
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


setup_network() {
  interface_config="inet ${INTERFACE_IP} netmask 255.255.255.0"
  interface_alias_config="inet ${JAIL_INTERFACE_IP} netmask 255.255.255.0"
  interface_ipv6_config="inet6 -ifdisabled auto_linklocal ${IPV6_PREFIX}${INTERFACE_IP6}"

  BRIDGE_MEMBERS_CONFIG=""
  for member in ${BRIDGE_MEMBERS}; do
    BRIDGE_MEMBERS_CONFIG="${BRIDGE_MEMBERS_CONFIG} addm ${member}"
  done
  if [ ! -z "${BRIDGE_MEMBERS_CONFIG}" ]; then
    interface_config="${interface_config}${BRIDGE_MEMBERS_CONFIG}"
  fi

  sysrc cloned_interfaces+="bridge0"
  sysrc ifconfig_bridge0_name="${INTERFACE}"
  if [ "${USE_IPV4}" = "yes" ]; then
    sysctl net.inet.ip.forwarding=1
    sysrc gateway_enable="YES"
    sysrc ifconfig_${INTERFACE}="${interface_config}"
    sysrc ifconfig_${INTERFACE}_alias0="${interface_alias_config}"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    sysrc ipv6_gateway_enable="YES"
    sysctl net.inet6.ip6.forwarding=1
    sysrc ifconfig_${INTERFACE}_ipv6="${interface_ipv6_config}"
  fi

  service netif cloneup
  sleep 1

  if [ "${USE_IPV4}" = "yes" ]; then
    ifconfig ${INTERFACE} ${interface_config}
    ifconfig ${INTERFACE} ${interface_alias_config} alias
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    ifconfig ${INTERFACE} ${interface_ipv6_config}
  fi
}


setup_pf() {
  if [ ! -e /etc/pf.conf ]; then
    sed \
      -e "s;EGRESS;${EGRESS};g" \
      -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
      -e "s;MASTER_IP6;${MASTER_IP6};g" \
      -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
      -e "s;JAIL_INTERFACE_IP;${JAIL_INTERFACE_IP};g" \
      -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
      -e "s;INTERFACE;${INTERFACE};g" \
      -e "s;MASTER_IP;${MASTER_IP};g" \
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
  if [ "${USE_IPV6}" = "yes" ]; then
    sysrc rtadvd_enable="YES"
    sysrc rtadvd_interfaces="cbsd0"
    sed \
      -e "s;INTERFACE;${INTERFACE};g" \
      -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
      "${SCRIPT_DIR}/../templates/rtadvd.conf" >/etc/rtadvd.conf
  fi
}


setup_nfs() {
  TMP_EXPORTS=`mktemp`
  sysrc mountd_enable="YES"
  sysrc mountd_flags="-r"
  sysrc nfs_server_enable="YES"
  sysrc nfsv4_server_enable="YES"
  sysrc rpcbind_enable="YES"

  if [ -e /etc/exports ]; then
    egrep -v '^V4:' /etc/exports >"${TMP_EXPORTS}"
  fi
  echo "${PROJECTS_DIR} -alldirs -network ${INTERFACE_IP} -mask 255.255.255.0" -maproot=root >>"${TMP_EXPORTS}"
  sort "${TMP_EXPORTS}" | uniq > /etc/exports
  echo "V4: /" >>/etc/exports

  service rpcbind start
  service nfsd start
  service mountd start
  rm "${TMP_EXPORTS}"
}


setup_unbound() {
  REVERSE_ZONE=`get_zone ipv4 ${INTERFACE_IP}`
  REVERSEV6=`get_zone ipv6 ${IPV6_PREFIX}${MASTER_IP6}`

  sysrc local_unbound_enable="YES"
  sysrc local_unbound_tls="NO"
  fetch -o /var/unbound/root.hints https://www.internic.net/domain/named.cache
  resolvconf -u
  service local_unbound restart
  sed \
    -e "s;JAIL_INTERFACE_IP;${JAIL_INTERFACE_IP};g" \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
    "${SCRIPT_DIR}/../templates/unbound.conf" >/var/unbound/unbound.conf
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    -e "s;MASTER_IP6;${MASTER_IP6};g" \
    -e "s;REVERSEV6;${REVERSEV6};g" \
    -e "s;REVERSE;${REVERSE_ZONE};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    "${SCRIPT_DIR}/../templates/unbound_cbsd.conf" >/var/unbound/cbsd.conf
  cp "${SCRIPT_DIR}/../templates/unbound_control.conf" /var/unbound/control.conf
  cp "${SCRIPT_DIR}/../templates/resolvconf.conf" /etc/resolvconf.conf

  chown -R unbound:unbound /var/unbound
  service local_unbound restart
  resolvconf -u
}


check_config
setup_network
setup_pf
setup_hostname
setup_rtadvd
setup_nfs
setup_unbound
