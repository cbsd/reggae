#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"

SERVICE="network"

setup() {
  if [ "${USE_IPV4}" != "yes" -a "${USE_IPV6}" != "yes" ]; then
    echo "IPv4 and/or IPv6 has to be enable, check USE_IPV{4,6} in config!" >&2
    exit 1
  fi
  if [ -z "${VER}" ]; then
    reggae mkjail network
  else
    env VERSION=${VER} reggae mkjail network
  fi
  mkdir -p "${BASE_WORKDIR}/${SERVICE}/usr/local/etc/pkg/repos"
  echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/pkg/repos/FreeBSD.conf"
  echo 'sendmail_enable="NONE"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/sendmail"
  echo "search $(hostname)" >"${BASE_WORKDIR}/${SERVICE}/etc/resolv.conf"
  if [ "${USE_IPV4}" = "yes" ]; then
    echo "ifconfig_eth0=\"inet ${MASTER_IP}/24\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "defaultrouter=\"${INTERFACE_IP}\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "nameserver ${INTERFACE_IP}" >>"${BASE_WORKDIR}/${SERVICE}/etc/resolv.conf"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    echo "ifconfig_eth0_ipv6=\"inet6 ${IPV6_PREFIX}${MASTER_IP6}/64\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "ipv6_defaultrouter=\"${IPV6_PREFIX}${INTERFACE_IP6}\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "nameserver ${IPV6_PREFIX}${INTERFACE_IP6}" >>"${BASE_WORKDIR}/${SERVICE}/etc/resolv.conf"
  fi
  service jail start network
  jexec ${SERVICE} env ASSUME_ALWAYS_YES=YES pkg bootstrap
  jexec ${SERVICE} pkg install -y isc-dhcp44-server nsd sudo
  echo "dhcpd ALL=(ALL) NOPASSWD: ALL" >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/sudoers.d/reggae"
  sysrc -s jail jail_list+="${SERVICE}"
}


dhcp() {
  cp ${SCRIPT_DIR}/../templates/dhcpd-hook.sh "${BASE_WORKDIR}/${SERVICE}/usr/local/bin/"
  chmod 755 "${BASE_WORKDIR}/${SERVICE}/usr/local/bin/dhcpd-hook.sh"
  cp ${SCRIPT_DIR}/../templates/reggae-register.sh "${BASE_WORKDIR}/${SERVICE}/usr/local/bin/"
  chmod 755 "${BASE_WORKDIR}/${SERVICE}/usr/local/bin/reggae-register.sh"
  jexec ${SERVICE} pw group mod nsd -m dhcpd
  jexec ${SERVICE} pwd_mkdb /etc/master.passwd

  if [ "${USE_IPV4}" = "yes" ]; then
    DHCP_BASE=$(echo ${MASTER_IP} | awk -F '.' '{print $1 "." $2 "." $3}')
    DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
    DHCP_SUBNET_LAST="${DHCP_BASE}.200"
    sed \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
      -e "s:MASTER_IP:${MASTER_IP}:g" \
      -e "s:DHCP_SUBNET_FIRST:${DHCP_SUBNET_FIRST}:g" \
      -e "s:DHCP_SUBNET_LAST:${DHCP_SUBNET_LAST}:g" \
      -e "s:DHCP_BASE:${DHCP_BASE}:g" \
      ${SCRIPT_DIR}/../templates/dhcpd.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/dhcpd.conf"
    echo 'dhcpd_enable="YES"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_flags="-q"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_conf="/usr/local/etc/dhcpd.conf"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_withumask="022"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_withgroup="nsd"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd"
    jexec ${SERVICE} service isc-dhcpd start
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    sed \
      -e "s;DOMAIN;${DOMAIN};g" \
      -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
      -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
      ${SCRIPT_DIR}/../templates/dhcpd6.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/dhcpd6.conf"
    echo 'dhcpd6_enable="YES"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd6"
    echo 'dhcpd6_withumask="022"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd6"
    echo 'dhcpd6_withgroup="nsd"' >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/dhcpd6"
    touch "${BASE_WORKDIR}/${SERVICE}/var/db/dhcpd6.leases"
    jexec ${SERVICE} service isc-dhcpd6 start
  fi
}


dns() {
  echo 'nsd_enable="YES"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/nsd"
  mkdir -p "${BASE_WORKDIR}/${SERVICE}/usr/local/etc/nsd/zones/master"
  mkdir -p "${BASE_WORKDIR}/${SERVICE}/usr/local/etc/nsd/zones/slave"
  sed \
    -e "s:DOMAIN:${DOMAIN}:g" \
    -e "s:REVERSE:${REVERSE_ZONE}:g" \
    "${SCRIPT_DIR}/../templates/nsd.conf" >${BASE_WORKDIR}/${SERVICE}/usr/local/etc/nsd/nsd.conf
  chmod -R g+w ${BASE_WORKDIR}/${SERVICE}/usr/local/etc/nsd
  chown -R root:216 ${BASE_WORKDIR}/${SERVICE}/usr/local/etc/nsd

  jexec ${SERVICE} nsd-control-setup
  jexec ${SERVICE} service nsd restart
  if [ "${USE_IPV4}" = "yes" ]; then
    jexec ${SERVICE} usr/local/bin/reggae-register.sh ipv4 add ${INTERFACE_IP} @ ${DOMAIN}
    jexec ${SERVICE} usr/local/bin/reggae-register.sh ipv4 add ${MASTER_IP} network ${DOMAIN}
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    jexec ${SERVICE} usr/local/bin/reggae-register.sh ipv6 add ${IPV6_PREFIX}${MASTER_IP6} @ ${DOMAIN}
    jexec ${SERVICE} /usr/local/bin/reggae-register.sh ipv6 add ${IPV6_PREFIX}${MASTER_IP6} network ${DOMAIN}
  fi
}


setup
dhcp
dns
