#!/bin/sh

set -e

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"
. "${SCRIPT_DIR}/helpers.sh"

HOSTNAME=$(hostname)
TEMP_MASTER_CONF=$(mktemp)
TEMP_DHCP_CONF=$(mktemp)
export VER=${VER:="native"}
SERVICE="network"
export ARCH=${ARCH:="$(uname -m)"}
export TARGET_ARCH=${TARGET_ARCH:="$(uname -p)"}

setup() {
  if [ "${USE_IPV4}" != "yes" -a "${USE_IPV6}" != "yes" ]; then
    echo "IPv4 and/or IPv6 has to be enable, check USE_IPV{4,6} in config!" >&2
    exit 1
  fi

  if [ -z "${VER}" -o "${VER}" = "native" ]; then
    tmpver=$( uname -r )
    VER=${tmpver%%-*}
    unset tmpver
  fi
  # or check for /bin/sh via: [ ! -x ${CBSD_WORKDIR}/basejail/base_${ARCH}_${TARGET_ARCH}_${VER}/bin/sh" ]  - whats about linux jail without /bin/sh ?
  if [ ! -d "${CBSD_WORKDIR}/basejail/base_${ARCH}_${TARGET_ARCH}_${VER}/bin" ]; then
    echo "no such bases: base_${ARCH}_${TARGET_ARCH}_${VER}/bin, fetch via 'cbsd repo'"
    cbsd repo action=get sources=base ver=${VER}
    # extra check for "${CBSD_WORKDIR}/basejail/base_${ARCH}_${TARGET_ARCH}_${VER}/bin" directory ?
  fi

  env NOINTER=1 cbsd jcreate jname=network host_hostname=network.${DOMAIN} runasap=0 vnet=1 b_order=0 devfs_ruleset=8 ip4_addr=${MASTER_IP},${IPV6_PREFIX}${MASTER_IP6} ci_gw4=${INTERFACE_IP},${IPV6_PREFIX}${INTERFACE_IP6} interface=${INTERFACE}
  mkdir -p "${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos"
  echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos/FreeBSD.conf"
  cp ${SCRIPT_DIR}/../templates/master.fstab "${CBSD_WORKDIR}/jails-fstab/${SERVICE}/fstab.local"
  cbsd jstart ${SERVICE}
  cbsd jexec jname=${SERVICE} cmd="env ASSUME_ALWAYS_YES=YES pkg bootstrap -f"
  cbsd jexec jname=${SERVICE} cmd="pkg install -y kea knot3"
}


dhcp() {
  echo 'kea_enable="YES"' >"${CBSD_WORKDIR}/${SERVICE}/etc/rc.conf.d/kea"
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
    ${SCRIPT_DIR}/../templates/kea-dhcp4.conf >"${CBSD_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp4.conf"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;INTERFACE_IP6;${INTERFACE_IP6};g" \
    -e "s;MASTER_IP6;${MASTER_IP6};g" \
    -e "s;IPV6_PREFIX;${IPV6_PREFIX};g" \
    ${SCRIPT_DIR}/../templates/kea-dhcp6.conf >"${CBSD_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp6.conf"
  sed \
    -e "s;DOMAIN;${DOMAIN};g" \
    -e "s;KEY;${KEY};g" \
    -e "s;REVERSE_IPV6;${REVERSE_IPV6_ZONE};g" \
    -e "s;REVERSE;${REVERSE_ZONE};g" \
    ${SCRIPT_DIR}/../templates/kea-dhcp-ddns.conf >"${CBSD_WORKDIR}/${SERVICE}/usr/local/etc/kea/kea-dhcp-ddns.conf"
  sed \
    -e "s;USE_IPV4;${USE_IPV4};g" \
    -e "s;USE_IPV6;${USE_IPV6};g" \
    ${SCRIPT_DIR}/../templates/keactrl.conf >"${CBSD_WORKDIR}/${SERVICE}/usr/local/etc/kea/keactrl.conf"
  cp ${SCRIPT_DIR}/../templates/kea.sh "${CBSD_WORKDIR}/${SERVICE}/usr/local/share/kea/scripts/"
  chmod 755 "${CBSD_WORKDIR}/${SERVICE}/usr/local/share/kea/scripts/kea.sh"
}


dns() {
  echo 'knot_enable="YES"' >"${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/rc.conf.d/knot"
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
