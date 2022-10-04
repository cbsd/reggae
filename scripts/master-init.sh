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
export VER=${VER:="native"}
SERVICE="network"


setup() {
  if [ "${USE_IPV4}" != "yes" -a "${USE_IPV6}" != "yes" ]; then
    echo "IPv4 or IPv6 has to be enable, check USE_IPV{4,6} in config!" >&2
    exit 1
  fi
  cbsd jcreate jname=network host_hostname=network.${DOMAIN} runasap=0 vnet=1 b_order=0 devfs_ruleset=8 ip4_addr=${MASTER_IP},${IPV6_PREFIX}${MASTER_IP6} ci_gw4=${INTERFACE_IP},${IPV6_PREFIX}${INTERFACE_IP6}
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos"
  echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos/FreeBSD.conf"
  echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/sendmail"
  cp ${SCRIPT_DIR}/../templates/master.fstab "${CBSD_WORKDIR}/jails-fstab/${SERVICE}/fstab.local"
  echo "#!/bin/sh" >"${CBSD_WORKDIR}/jails-system/network/master_poststart.d/reggae.sh"
  echo "service reggae onerestart" >>"${CBSD_WORKDIR}/jails-system/network/master_poststart.d/reggae.sh"
  echo "service reggae_pf onerestart" >>"${CBSD_WORKDIR}/jails-system/network/master_poststart.d/reggae.sh"
  chmod +x "${CBSD_WORKDIR}/jails-system/network/master_poststart.d/reggae.sh"
  mkdir /var/run/reggae &>/dev/null
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
  if [ "${USE_IPV4}" = "yes" ]; then
    sed \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
      -e "s:MASTER_IP:${MASTER_IP}:g" \
      -e "s:DHCP_SUBNET_FIRST:${DHCP_SUBNET_FIRST}:g" \
      -e "s:DHCP_SUBNET_LAST:${DHCP_SUBNET_LAST}:g" \
      -e "s:DHCP_BASE:${DHCP_BASE}:g" \
      ${SCRIPT_DIR}/../templates/dhcpd.conf >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/dhcpd.conf"
    echo 'dhcpd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_flags="-q"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_conf="/usr/local/etc/dhcpd.conf"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_withumask="022"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_withgroup="nsd"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    sed \
      -e "s;DOMAIN;${DOMAIN};g" \
      -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
      -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
      ${SCRIPT_DIR}/../templates/dhcpd6.conf >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/dhcpd6.conf"
    echo 'dhcpd6_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd6"
    echo 'dhcpd6_withumask="022"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd6"
    echo 'dhcpd6_withgroup="nsd"' >>"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/dhcpd6"
    touch "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/var/db/dhcpd6.leases"
  fi
  sed \
    -e "s:MASTER_IP:${MASTER_IP}:g" \
    ${SCRIPT_DIR}/../templates/ip-by-mac.sh >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/ip-by-mac.sh"
  chmod 755 "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/bin/ip-by-mac.sh"

  cbsd jexec jname=${SERVICE} cmd="pw group mod nsd -m dhcpd"
  cbsd jexec jname=${SERVICE} cmd="pwd_mkdb /etc/master.passwd"
  cbsd jexec jname=${SERVICE} cmd="service isc-dhcpd restart"
  if [ "${USE_IPV6}" = "yes" ]; then
    cbsd jexec jname=${SERVICE} cmd="service isc-dhcpd6 restart"
  fi
}


dns() {
  echo 'nsd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/nsd"
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/master"
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/zones/slave"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:REVERSE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/nsd.conf" >${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd/nsd.conf

  chmod -R g+w ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd
  chown -R root:216 ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/nsd
  cbsd jexec jname=${SERVICE} cmd="nsd-control-setup"
  cbsd jexec jname=${SERVICE} cmd="service nsd restart"
  if [ "${USE_IPV4}" = "yes" ]; then
    cbsd jexec jname=${SERVICE} cmd="/usr/local/bin/reggae-register.sh ipv4 add ${INTERFACE_IP} @ ${DOMAIN}"
    cbsd jexec jname=${SERVICE} cmd="/usr/local/bin/reggae-register.sh ipv4 add ${MASTER_IP} network ${DOMAIN}"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    cbsd jexec jname=${SERVICE} cmd="/usr/local/bin/reggae-register.sh ipv6 add ${IPV6_PREFIX}${MASTER_IP6} @ ${DOMAIN}"
    cbsd jexec jname=${SERVICE} cmd="/usr/local/bin/reggae-register.sh ipv6 add ${IPV6_PREFIX}${MASTER_IP6} network ${DOMAIN}"
  fi
}


setup
dhcp
dns
