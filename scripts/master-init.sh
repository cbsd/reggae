#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

HOSTNAME=`hostname`
EGRESS=`netstat -rn4 | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_MASTER_CONF=`mktemp`
TEMP_DHCP_CONF=`mktemp`
PKG_PROXY=`reggae get-config PKG_PROXY`
IPV6_PREFIX=`reggae get-config IPV6_PREFIX`
INTERFACE_IP=`reggae get-config INTERFACE_IP`
export VER=${VER:="native"}
SERVICE="network"


setup() {
  sed \
    -e "s;CBSD_WORKDIR;${CBSD_WORKDIR};g" \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    -e "s;VERSION;${VER};g" \
    -e "s;SERVICE;${SERVICE};g" \
    -e "s;DEVFS_RULESET;8;g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
    ${SCRIPT_DIR}/../templates/master.conf >"${TEMP_MASTER_CONF}"

  cbsd jcreate inter=0 jconf="${TEMP_MASTER_CONF}"
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos"
  echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos/FreeBSD.conf"
  echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/sendmail"
  cp ${SCRIPT_DIR}/../templates/master.fstab "${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local"
  cbsd jset jname=${SERVICE} b_order=0
  cbsd jstart ${SERVICE}
  cbsd jexec jname=${SERVICE} cmd="env ASSUME_ALWAYS_YES=YES pkg bootstrap"
  cbsd jexec jname=${SERVICE} cmd="pkg install -y isc-dhcp44-server nsd sudo"
  echo "dhcpd ALL=(ALL) NOPASSWD: ALL" >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/sudoers.d/reggae"
}


dhcp() {
  cp ${SCRIPT_DIR}/../templates/dhcpd-hook.sh "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/"
  chmod 755 "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/dhcpd-hook.sh"
  cp ${SCRIPT_DIR}/../templates/reggae-register.sh "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/"
  chmod 755 "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/reggae-register.sh"
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
    ${SCRIPT_DIR}/../templates/dhcpd.conf >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/dhcpd.conf"
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    ${SCRIPT_DIR}/../templates/ip-by-mac.sh >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/ip-by-mac.sh"
  chmod 755 "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/ip-by-mac.sh"
  echo 'dhcpd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_flags="-q"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_conf="/usr/local/etc/dhcpd.conf"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_withumask="022"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
  echo 'dhcpd_withgroup="nsd"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"

  cbsd jexec jname=${SERVICE} cmd="pw group mod nsd -m dhcpd"
  cbsd jexec jname=${SERVICE} cmd="pwd_mkdb /etc/master.passwd"
  cbsd jexec jname=${SERVICE} cmd="service isc-dhcpd restart"
}


dns() {
  REVERSE_ZONE=`echo ${INTERFACE_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
  REVERSE_ZONE_FILE="${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/master/${REVERSE_ZONE}"
  LAST_OCTET=`echo "${INTERFACE_IP}" | awk -F '.' '{print $4}'`

  echo 'nsd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/nsd"
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/master"
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/slave"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:REVERSE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/nsd.conf" >${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/nsd.conf

  ZONE_FILE="${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/master/${DOMAIN}"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
    "${SCRIPT_DIR}/../templates/cbsd.zone" >"${ZONE_FILE}"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:ZONE:${REVERSE_ZONE}:g" \
    -e "s:LAST_OCTET:${LAST_OCTET}:g" \
    "${SCRIPT_DIR}/../templates/cbsd_reverse.zone" >"${REVERSE_ZONE_FILE}"

  chmod -R g+w ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd
  chown -R root:216 ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd
  cbsd jexec jname=${SERVICE} cmd="nsd-control-setup"
  cbsd jexec jname=${SERVICE} cmd="service nsd restart"
}


setup
dhcp
dns
