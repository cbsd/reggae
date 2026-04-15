#!/bin/sh

set -e

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"
. "${SCRIPT_DIR}/helpers.sh"

SERVICE="network"

setup() {
  if [ "${USE_IPV4}" != "yes" -a "${USE_IPV6}" != "yes" ]; then
    echo "IPv4 and/or IPv6 has to be enable, check USE_IPV{4,6} in config!" >&2
    exit 1
  fi
  fstab_file="$(mktemp)"
  echo "/var/unbound \${path}/var/unbound nullfs rw 0 0" >"${fstab_file}"
  if [ -z "${VER}" ]; then
    reggae mkjail -f "${fstab_file}" network
  else
    env VERSION=${VER} reggae mkjail -f "${fstab_file}" network
  fi
  rm -rf "${fstab_file}"
  if [ "${USE_IPV4}" = "yes" ]; then
    echo "ifconfig_eth0=\"inet ${MASTER_IP}/24\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "defaultrouter=\"${INTERFACE_IP}\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    echo "ifconfig_eth0_ipv6=\"inet6 ${IPV6_PREFIX}${MASTER_IP6}/64\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
    echo "ipv6_defaultrouter=\"${IPV6_PREFIX}${INTERFACE_IP6}\"" >>"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf"
  fi
  pkg --chroot "${BASE_WORKDIR}/${SERVICE}" install -y kea knot3
  sysrc -s jail jail_list+="${SERVICE}"
  export KEY="$(openssl rand -base64 32)"
}


dhcp() {
  echo 'kea_enable="YES"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/kea"
  DHCP_BASE=$(echo ${MASTER_IP} | awk -F '.' '{print $1 "." $2 "." $3}')
  DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
  DHCP_SUBNET_LAST="${DHCP_BASE}.200"
  REVERSE_ZONE=$(get_zone ipv4 ${INTERFACE_IP})
  REVERSE_IPV6_ZONE=$(get_zone ipv6 ${IPV6_PREFIX}${INTERFACE_IP6})
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    -e "s;DHCP_SUBNET_FIRST;${DHCP_SUBNET_FIRST};g" \
    -e "s;DHCP_SUBNET_LAST;${DHCP_SUBNET_LAST};g" \
    -e "s;DHCP_BASE;${DHCP_BASE};g" \
    ${SCRIPT_DIR}/../templates/kea-dhcp4.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp4.conf"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
    -e "s;MASTER_IP6;${MASTER_IP6};g" \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    ${SCRIPT_DIR}/../templates/kea-dhcp6.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp6.conf"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;KEY;${KEY};g" \
    -e "s;REVERSE_IPV6;${REVERSE_IPV6_ZONE};g" \
    -e "s;REVERSE;${REVERSE_ZONE};g" \
    ${SCRIPT_DIR}/../templates/kea-dhcp-ddns.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp-ddns.conf"
  sed \
    -e "s;USE_IPV4;${USE_IPV4};g" \
    -e "s;USE_IPV6;${USE_IPV6};g" \
    ${SCRIPT_DIR}/../templates/keactrl.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/kea/keactrl.conf"
  cp ${SCRIPT_DIR}/../templates/kea.sh "${BASE_WORKDIR}/${SERVICE}/usr/local/share/kea/scripts/"
  chmod 755 "${BASE_WORKDIR}/${SERVICE}/usr/local/share/kea/scripts/kea.sh"
}


dns() {
  echo 'knot_enable="YES"' >"${BASE_WORKDIR}/${SERVICE}/etc/rc.conf.d/knot"
  SERIAL="$(date '+%Y%m%d%H')"
  REVERSE_ZONE=$(get_zone ipv4 ${INTERFACE_IP})
  REVERSE_IP=$(get_ptr ipv4 ${INTERFACE_IP})
  REVERSE_MASTER_IP=$(get_ptr ipv4 ${MASTER_IP})
  REVERSE_IPV6_ZONE=$(get_zone ipv6 ${IPV6_PREFIX}${INTERFACE_IP6})
  REVERSE_IP6=$(get_ptr ipv6 ${IPV6_PREFIX}${INTERFACE_IP6})
  REVERSE_MASTER_IP6=$(get_ptr ipv6 ${IPV6_PREFIX}${MASTER_IP6})
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;MASTER_IP6;${MASTER_IP6};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    -e "s;KEY;${KEY};g" \
    -e "s;REVERSE_IPV6_ZONE;${REVERSE_IPV6_ZONE};g" \
    -e "s;REVERSE_ZONE;${REVERSE_ZONE};g" \
    ${SCRIPT_DIR}/../templates/knot.conf >"${BASE_WORKDIR}/${SERVICE}/usr/local/etc/knot/knot.conf"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    -e "s;SERIAL;${SERIAL};g" \
    ${SCRIPT_DIR}/../templates/domain.zone >"${BASE_WORKDIR}/${SERVICE}/var/db/knot/${DOMAIN}.zone"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP};g" \
    -e "s;SERIAL;${SERIAL};g" \
    -e "s;REVERSE_MASTER_IP;${REVERSE_MASTER_IP};g" \
    -e "s;REVERSE_IP;${REVERSE_IP};g" \
    -e "s;REVERSE;${REVERSE_ZONE};g" \
    -e "s;MASTER_IP;${MASTER_IP};g" \
    ${SCRIPT_DIR}/../templates/reverse.zone >"${BASE_WORKDIR}/${SERVICE}/var/db/knot/${REVERSE_ZONE}.zone"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP;${INTERFACE_IP6};g" \
    -e "s;SERIAL;${SERIAL};g" \
    -e "s;REVERSE_MASTER_IP;${REVERSE_MASTER_IP6};g" \
    -e "s;REVERSE_IP;${REVERSE_IP6};g" \
    -e "s;REVERSE;${REVERSE_IPV6_ZONE};g" \
    -e "s;MASTER_IP;${MASTER_IP6};g" \
    ${SCRIPT_DIR}/../templates/reverse.zone >"${BASE_WORKDIR}/${SERVICE}/var/db/knot/${REVERSE_IPV6_ZONE}.zone"
}


setup
dhcp
dns
service jail start network
