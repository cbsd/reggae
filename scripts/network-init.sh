#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

SSHD_FLAGS=`sysrc -n sshd_flags`
SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
CLONED_INTERFACES=`sysrc -n cloned_interfaces`
NATIP=`netstat -rn | awk '/^default/{print $2}'`
EGRESS=`netstat -rn4 | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
STATIC=NO


if [ -z "${DHCP_CONFIG}" ]; then
    STATIC=YES
fi


check_config() {
  if [ -z "${PROJECTS_DIR}" ]; then
    echo "PROJECTS_DIR must be set in /usr/local/etc/reggae.conf" >&2
    exit 1
  fi
}


network() {
  interface_config="inet ${INTERFACE_IP} netmask 255.255.255.0 description ${EGRESS}"
  interface_alias_config="inet ${JAIL_INTERFACE_IP} netmask 255.255.255.0"
  sysctl net.inet.ip.forwarding=1
  sysrc gateway_enable="YES"
  sysrc cloned_interfaces+="bridge0"
  sysrc ifconfig_bridge0_name="${INTERFACE}"
  sysrc ifconfig_${INTERFACE}="${interface_config}"
  sysrc ifconfig_${INTERFACE}_alias0="${interface_alias_config}"
  service netif cloneup
  sleep 1
  ifconfig ${INTERFACE} ${interface_config}
  ifconfig ${INTERFACE} ${interface_alias_config} alias
}


pf() {
  if [ ! -e /etc/pf.conf ]; then
    RDR=""
    if [ "${STATIC}" = "NO" ]; then
      RDR="rdr pass on \$ext_if proto tcp from any to any port ssh -> 127.0.0.1"
    fi
    sed \
      -e "s:EGRESS:${EGRESS}:g" \
      -e "s:JAIL_INTERFACE_IP:${JAIL_INTERFACE_IP}:g" \
      -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
      -e "s:INTERFACE:${INTERFACE}:g" \
      -e "s:RDR:${RDR}:g" \
      "${SCRIPT_DIR}/../templates/pf.conf" >/etc/pf.conf
  fi
  sysrc pflog_enable="YES"
  sysrc pf_enable="YES"
}


setup_hostname() {
    if [ "${HOSTNAME}" == "${SHORT_HOSTNAME}" ]; then
        HOSTNAME="${SHORT_HOSTNAME}.${DOMAIN}"
        hostname ${HOSTNAME}
        sysrc hostname="${HOSTNAME}"
    fi
}


setup_ssh() {
  if [ -z "${SSHD_FLAGS}" ]; then
    sysrc sshd_flags="-o ListenAddress=127.0.0.1"
  else
    sysrc sshd_flags+=" -o ListenAddress=127.0.0.1"
  fi
  if [ "${STATIC}" = "YES" ]; then
    EGRESS_IP=`echo ${EGRESS_CONFIG} | grep -E 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}'`
    sysrc sshd_flags+=" -o ListenAddress=${EGRESS_IP}"
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
    cp /etc/exports "${TMP_EXPORTS}"
  fi
  echo "${PROJECTS_DIR} -alldirs -network ${INTERFACE_IP} -mask 255.255.255.0" >>"${TMP_EXPORTS}"
  sort "${TMP_EXPORTS}" | uniq > /etc/exports

  service rpcbind start
  service nfsd start
  service mountd start
  rm "${TMP_EXPORTS}"
}


setup_unbound() {
  mkdir /var/run/unbound
  chown unbound:unboud /var/run/unbound
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
    "${SCRIPT_DIR}/../templates/unbound_cbsd.conf" >/var/unbound/conf.d/cbsd.conf
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
    "${SCRIPT_DIR}/../templates/unbound_cbsd.zone" >/var/unbound/conf.d/cbsd.zone
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
setup_ssh
setup_nfs
setup_unbound
