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


network() {
    sysrc gateway_enable="YES"
    sysctl net.inet.ip.forwarding=1

    rm -rf /tmp/ifaces.txt
    touch /tmp/ifaces.txt
    for iface in ${CLONED_INTERFACES}; do
        echo "${iface}" >>/tmp/ifaces.txt
    done

    LO_INTERFACE=`grep "^${JAIL_INTERFACE}$" /tmp/ifaces.txt`
    if [ -z "${LO_INTERFACE}" ]; then
        if [ -z "${CLONED_INTERFACES}" ]; then
            CLONED_INTERFACES="${JAIL_INTERFACE}"
        else
            CLONED_INTERFACES="${CLONED_INTERFACES} ${JAIL_INTERFACE}"
        fi
        sysrc ifconfig_lo1="up"
    fi

    BRIDGE_INTERFACE=`grep "^${VM_INTERFACE}$" /tmp/ifaces.txt`
    if [ -z "${BRIDGE_INTERFACE}" ]; then
        CLONED_INTERFACES="${CLONED_INTERFACES} ${VM_INTERFACE}"
        sysrc ifconfig_${VM_INTERFACE}="inet ${VM_INTERFACE_IP} netmask 255.255.255.0 description ${EGRESS}"
    fi

    sysrc cloned_interfaces="${CLONED_INTERFACES}"
    service netif cloneup
    rm -rf /tmp/ifaces.txt
}


pf() {
    if [ ! -e /etc/pf.conf ]; then
      RDR=""
      if [ "${STATIC}" = "NO" ]; then
        RDR="rdr pass on \$ext_if proto tcp from any to any port ssh -> 127.0.0.1"
      fi
      RESOLVER_BASE=`echo ${RESOLVER_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
      JAIL_IP_POOL="${RESOLVER_BASE}.0/24"
      DHCP_BASE=`echo ${DHCP_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
      VM_IP_POOL="${DHCP_BASE}.0/24"
      sed \
        -e "s:EGRESS:${EGRESS}:g" \
        -e "s:VM_INTERFACE:${VM_INTERFACE}:g" \
        -e "s:JAIL_INTERFACE:${JAIL_INTERFACE}:g" \
        -e "s:JAIL_IP_POOL:${JAIL_IP_POOL}:g" \
        -e "s:VM_IP_POOL:${VM_IP_POOL}:g" \
        -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
        -e "s:RDR:${RDR}:g" \
        "${SCRIPT_DIR}/../templates/pf.conf" >/etc/pf.conf
      sysrc pflog_enable="YES"
      sysrc pf_enable="YES"
    fi
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
    SSHD_FLAGS="${SSHD_FLAGS} -o ListenAddress=127.0.0.1"
    if [ "${STATIC}" = "YES" ]; then
      EGRESS_IP=`echo ${EGRESS_CONFIG} | grep -E 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}'`
      SSHD_FLAGS="${SSHD_FLAGS} -o ListenAddress=${EGRESS_IP}"
    fi
    sysrc sshd_flags="${SSHD_FLAGS}"
  fi
}


network
pf
setup_hostname
setup_ssh
