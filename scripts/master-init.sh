#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

HOSTNAME=`hostname`
EGRESS=`netstat -rn | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_MASTER_CONF=`mktemp`
TEMP_DHCP_CONF=`mktemp`


resolver() {
  sed \
    -e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE:${INTERFACE}:g" \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    ${SCRIPT_DIR}/../templates/master.conf >"${TEMP_MASTER_CONF}"

  ZONE_BASE=${DOMAIN}

  cbsd jcreate inter=0 jconf="${TEMP_MASTER_CONF}"
  echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/sendmail"
  echo 'named_enable="YES"' >"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/named"
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    "${SCRIPT_DIR}/../templates/rndc.conf" \
    >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/rndc.conf"
  cbsd jstart cbsd
  if [ ! -f "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/cbsd.key" ]; then
      cbsd jexec jname=cbsd rndc-confgen -a -c /usr/local/etc/namedb/cbsd.key -k cbsd
      chown bind:bind "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/cbsd.key"
  fi
  RNDC_KEY=`awk -F '"' '/secret/{print $2}' "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/cbsd.key"`
  REVERSE_ZONE=`echo ${INTERFACE_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  MASTER_IP_LAST=`echo ${INTERFACE_IP} | awk -F '.' '{print $4}'`
  JAIL_REVERSE_ZONE=`echo ${JAIL_INTERFACE_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    -e "s:ZONE_BASE:${ZONE_BASE}:g" \
    -e "s:JAIL_REVERSE_ZONE:${JAIL_REVERSE_ZONE}:g" \
    -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/named.conf" \
    >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/named.conf"
  sed \
    -e "s:ZONE_BASE:${ZONE_BASE}:g" \
    -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/my.domain.rev" \
    >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.rev"
  echo "${MASTER_IP_LAST} PTR cbsd.${ZONE_BASE}" \
    >>"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.rev"

  sed \
    -e "s:ZONE_BASE:${ZONE_BASE}:g" \
    -e "s:REVERSE_ZONE:${JAIL_REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/my.domain.rev" \
    >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.jail.rev"
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    -e "s:ZONE_BASE:${ZONE_BASE}:g" \
    "${SCRIPT_DIR}/../templates/my.domain" \
    >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}"

  echo "Changing permissions"
  chown bind:bind \
    "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}" \
    "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.rev"
  echo "Permissions changed"

  cbsd jexec jname=cbsd service named restart
}


dhcp() {
  cp ${SCRIPT_DIR}/../templates/dhcpd-hook.sh "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/"
  chmod 755 "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/dhcpd-hook.sh"
  DHCP_BASE=`echo ${MASTER_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
  REVERSE_ZONE=`echo ${MASTER_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
  DHCP_SUBNET_LAST="${DHCP_BASE}.200"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
    -e "s:DHCP_SUBNET_FIRST:${DHCP_SUBNET_FIRST}:g" \
    -e "s:DHCP_SUBNET_LAST:${DHCP_SUBNET_LAST}:g" \
    -e "s:DHCP_BASE:${DHCP_BASE}:g" \
    ${SCRIPT_DIR}/../templates/dhcpd.conf >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/dhcpd.conf"
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    ${SCRIPT_DIR}/../templates/ip-by-mac.sh >"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/ip-by-mac.sh"
  chmod 755 "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/ip-by-mac.sh"
  echo 'dhcpd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_flags="-q"' >>"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"
  echo "dhcpd_ifaces=\"${INTERFACE}\"" >>"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_conf="/usr/local/etc/dhcpd.conf"' >>"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_withumask="022"' >>"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"

  cbsd jexec jname=cbsd service isc-dhcpd restart
}


resolver
dhcp
