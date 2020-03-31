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


dhcp() {
  sed \
    -e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE:${INTERFACE}:g" \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    ${SCRIPT_DIR}/../templates/master.conf >"${TEMP_MASTER_CONF}"

  cbsd jcreate inter=0 jconf="${TEMP_MASTER_CONF}"
  mkdir -p "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/pkg/repos"
  echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/etc/pkg/repos/FreeBSD.conf"
  echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/sendmail"
  cp ${SCRIPT_DIR}/../templates/master.fstab "${CBSD_WORKDIR}/jails-fstab/fstab.cbsd.local"
  cbsd jset jname=cbsd b_order=0
  cbsd jstart cbsd
  cbsd jexec jname=cbsd env ASSUME_ALWAYS_YES=YES pkg bootstrap
  cbsd jexec jname=cbsd pkg install -y isc-dhcp44-server

  cp ${SCRIPT_DIR}/../templates/dhcpd-hook.sh "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/"
  chmod 755 "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/dhcpd-hook.sh"
  cp ${SCRIPT_DIR}/../templates/reggae-register.sh "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/"
  chmod 755 "${CBSD_WORKDIR}/jails-data/cbsd-data/usr/local/bin/reggae-register.sh"
  DHCP_BASE=`echo ${MASTER_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
  DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
  DHCP_SUBNET_LAST="${DHCP_BASE}.200"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
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
  echo 'dhcpd_withgroup="unbound"' >>"${CBSD_WORKDIR}/jails-data/cbsd-data/etc/rc.conf.d/dhcpd"

  cbsd jexec jname=cbsd pw group mod unbound -m dhcpd
  cbsd jexec jname=cbsd pwd_mkdb /etc/master.passwd
  cbsd jexec jname=cbsd service isc-dhcpd restart
}


dhcp
