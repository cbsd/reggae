#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

NAME="${1}"
if [ -z "${NAME}" ]; then
  echo "Usage: $0 <jail>" >&2
  exit 1
fi


POOL="${POOL:=zroot}"
export OS_VERSION_FLAVOR=${OS_VERSION_FLAVOR:="releases"}
export OS_VERSION_NAME=${OS_VERSION_NAME:="RELEASE"}
if [ -z "${OS_VERSION}" ]; then
  OS_VERSION=$(freebsd-version -k | cut -f 1 -d '-')
  RAW_VERSION_NAME=$(freebsd-version -k | cut -f 2 -d '-')
  if [ "${RAW_VERSION_NAME}" = "CURRENT" ]; then
    export OS_VERSION_NAME="CURRENT"
    export OS_VERSION_FLAVOR="snapshots"
  fi
fi
export DISTRIBUTIONS="base.txz"
export BSDINSTALL_DISTSITE="http://download.freebsd.org/${OS_VERSION_FLAVOR}/amd64/${OS_VERSION}-${OS_VERSION_NAME}"
export BSDINSTALL_CHROOT="${BASE_WORKDIR}/${NAME}"
export BSDINSTALL_DISTDIR="/usr/freebsd-dist/${OS_VERSION}"


next_id() {
  NEXT_ID=$(grep -s '$id = ' /etc/jail.conf)
  if [ -z "${NEXT_ID}" ]; then
    echo 1
  else
    expr $(grep '$id' /etc/jail.conf | \
      cut -f 2 -d '{' | \
      cut -f 1 -d ';' | \
      awk -F '= ' '{print $2}' | \
      sort -n | \
      tail -n 1 \
    ) + 1
  fi
}


check() {
  if [ -e "${BSDINSTALL_CHROOT}" ]; then
    echo "${BSDINSTALL_CHROOT} already exists" >&2
    exit 1
  fi
  EXISTING=$(grep "^${NAME} {" /etc/jail.conf)
  if [ ! -z "${EXISTING}" ]; then
    echo "${NAME} already defined in /etc/jail.conf as" >&2
    echo "${EXISTING}" >&2
    exit 1
  fi
}


check

if [ ! -d "${BSDINSTALL_DISTDIR}" ]; then
  mkdir -p "${BSDINSTALL_DISTDIR}"
  bsdinstall distfetch
fi
if [ "${USE_ZFS}" = "yes" ]; then
  zfs create -p "${POOL}${BSDINSTALL_CHROOT}"
else
  mkdir -p "${BSDINSTALL_CHROOT}"
fi
bsdinstall distextract
chroot "${BSDINSTALL_CHROOT}" pw group add provision -g 2001
chroot "${BSDINSTALL_CHROOT}" pw user add provision -u 2001 -g provision -s /bin/tcsh -G wheel -m
chroot "${BSDINSTALL_CHROOT}" chpass -p '$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/' provision
mkdir -p "${BSDINSTALL_CHROOT}/home/provision/.ssh"
chmod 700 "${BSDINSTALL_CHROOT}/home/provision/.ssh"


ID=`next_id`
if [ "${NAME}" = "network" ]; then
  cat "${SCRIPT_DIR}/../templates/network-jail.conf" >>/etc/jail.conf
else
  if [ -z "${DEPENDS}" ]; then
    echo "${NAME} { \$id = ${ID}; }" >>/etc/jail.conf
  else
    echo "${NAME} { \$id = ${ID}; depend = ${DEPENDS}; }" >>/etc/jail.conf
  fi
  if [ "${USE_IPV4}" = "yes" ]; then
    echo "ifconfig_eth0=\"DHCP\"" >>"${BSDINSTALL_CHROOT}/etc/rc.conf"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    echo "ifconfig_eth0_ipv6=\"inet6 -ifdisabled accept_rtadv auto_linklocal\"" >>"${BSDINSTALL_CHROOT}/etc/rc.conf"
  fi
fi
