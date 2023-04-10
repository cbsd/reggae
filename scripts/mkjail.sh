#!/bin/sh

set -e

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"
. "${SCRIPT_DIR}/utils.sh"

if [ "${USE_IPV4}" != "yes" -a "${USE_IPV6}" != "yes" ]; then
  echo "IPv4 and/or IPv6 has to be enable, check USE_IPV{4,6} in config!" >&2
  exit 1
fi

help() {
  echo "Usage: ${0} [options] <jail>"
  echo ""
  echo "options:"
  echo "  -d <list of jails>"
  echo "    Lilt of jails this jail depends on."
  echo "  -f <path to fstab file>"
  echo "    Aditional mount points defined in <path to fstab file>."
}

UPDATE=${UPDATE:=yes}
DEPS=""
FSTAB=""
optstring="d:f:"
args=$(getopt "${optstring}" ${*})
if [ $? -ne 0 ]; then
  help >&2
  exit 1
fi
set -- ${args}
while :; do
  case "${1}" in
    -d)
      DEPS="${2}"
      shift; shift
      ;;
    -f)
      FSTAB="${2}"
      shift; shift
      ;;
    --)
      shift
      break
    ;;
  esac
done


NAME="${1}"
if [ -z "${NAME}" ]; then
  help >&2
  exit 1
fi


POOL="${POOL:=zroot}"
export OS_VERSION_FLAVOR=${OS_VERSION_FLAVOR:="releases"}
export OS_VERSION_NAME=${OS_VERSION_NAME:="RELEASE"}
if [ -z "${OS_VERSION}" -o "${OS_VERSION}" = "native" ]; then
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
export PAGER=cat
if [ "${PKG_PROXY}" != "no" ]; then
  export HTTP_PROXY="${PKG_PROXY}"
fi


get_mounts() {
  if [ -z "${FSTAB}" ]; then
    return
  fi
  if [ -f "${FSTAB}" ]; then
    cat "${FSTAB}" | while read mountpoint; do
      mount_dest=$(eval echo ${mountpoint} | awk '{print $2}')
      mkdir -p "${BSDINSTALL_CHROOT}${mount_dest}"
      echo -n "\n mount += \"${mountpoint}\";"
    done
  fi
}


get_dependencies() {
  if [ -z "${DEPS}" ]; then
    return
  fi
  echo -n " depend = ${DEPS};"
}


generate_mac() {
  echo -n "58:9c:fc:"
  hexdump -n 3 -ve '1/1 "%.2x "' /dev/random |\
    awk -v a="2,3,a,e" -v r="$RANDOM" '
        BEGIN {
            srand(r);
        }
        NR==1 {
            split(a, b, ",");
            r=int(rand() * 4 + 1);
            printf("%s%s:%s:%s", substr($1, 0, 1), b[r], $2, $3);
        }
    '
}


check "${NAME}" "${BSDINSTALL_CHROOT}"

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
sed -i "" -e "s/^Components .*/Components world/" "${BSDINSTALL_CHROOT}/etc/freebsd-update.conf"
mkdir -p "${BSDINSTALL_CHROOT}/usr/local/etc/pkg/repos"
echo -e "FreeBSD: {\n    url: \"pkg+http://${PKG_MIRROR}/\${ABI}/${PKG_REPO}\",\n}">"${BSDINSTALL_CHROOT}/usr/local/etc/pkg/repos/FreeBSD.conf"
echo "search $(hostname)" >"${BSDINSTALL_CHROOT}/etc/resolv.conf"
if [ "${USE_IPV4}" = "yes" ]; then
  echo "nameserver ${INTERFACE_IP}" >>"${BSDINSTALL_CHROOT}/etc/resolv.conf"
fi
if [ "${USE_IPV6}" = "yes" ]; then
  echo "nameserver ${IPV6_PREFIX}${INTERFACE_IP6}" >>"${BSDINSTALL_CHROOT}/etc/resolv.conf"
fi
if [ "${UPDATE}" != "no" -a "${OS_VERSION_NAME}" = "RELEASE" ]; then
  chroot "${BSDINSTALL_CHROOT}" freebsd-update fetch install
fi
chroot "${BSDINSTALL_CHROOT}" pw group add provision -g 666
chroot "${BSDINSTALL_CHROOT}" pw user add provision -u 666 -g provision -s /bin/tcsh -G wheel -m
chroot "${BSDINSTALL_CHROOT}" chpass -p '$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/' provision
chroot "${BSDINSTALL_CHROOT}" service sshd enable
mkdir -p "${BSDINSTALL_CHROOT}/home/provision/.ssh"
chmod 700 "${BSDINSTALL_CHROOT}/home/provision/.ssh"
cp ~/.ssh/id_rsa.pub "${BSDINSTALL_CHROOT}/usr/home/provision/.ssh/authorized_keys"
chmod 600 "${BSDINSTALL_CHROOT}/usr/home/provision/.ssh/authorized_keys"
chown -R 666:666 "${BSDINSTALL_CHROOT}/usr/home/provision/.ssh"
env ASSUME_ALWAYS_YES=yes pkg -c "${BSDINSTALL_CHROOT}" bootstrap -f
sed -i "" \
  -e 's;PKG_PROXY;pkg_env : { http_proxy: "http://${PKG_PROXY}" };g' \
  "${SCRIPT_DIR}/../templates/pkg.conf" >"${BSDINSTALL_CHROOT}/usr/local/etc/pkg.conf"
pkg -c "${BSDINSTALL_CHROOT}" install -y sudo
echo "provision ALL=(ALL) NOPASSWD: ALL" >"${BSDINSTALL_CHROOT}/usr/local/etc/sudoers.d/reggae"


ID=$(next_id)
MAC=$(generate_mac)
HOST=$(hostname)

if [ "${NAME}" = "network" ]; then
  sed -e "s;HOST;${HOST};g" \
      -e "s;BASE_WORKDIR;${BASE_WORKDIR};g" \
      -e "s;INTERFACE;${INTERFACE};g" \
    "${SCRIPT_DIR}/../templates/network-jail.conf" >"/etc/jail.conf.d/${NAME}.conf"
else
  MOUNTS=$(get_mounts)
  DEPENDS=$(get_dependencies)
  if [ ! -z "${PRESTART}" ]; then
    PRESTART="\n exec.prestart += \"${PRESTART}\";"
  fi
  if [ ! -z "${POSTSTART}" ]; then
    POSTSTART="\n exec.poststart += \"${POSTSTART}\";"
  fi
  if [ ! -z "${PRESTOP}" ]; then
    PRESTOP="\n exec.prestop += \"${PRESTOP}\";"
  fi
  if [ ! -z "${POSTSTOP}" ]; then
    POSTSTOP="\n exec.poststop += \"${POSTSTOP}\";"
  fi
  OPTIONS="${MOUNTS}${DEPENDS}${PRESTART}${POSTSTART}${PRESTOP}${PRESTOP}"
  cat << EOF >"/etc/jail.conf.d/${NAME}.conf"
${NAME} {
  \$id = ${ID};
EOF
  sed \
    -e "s;HOST;${HOST};g" \
    -e "s;BASE_WORKDIR;${BASE_WORKDIR};g" \
    -e "s;INTERFACE;${INTERFACE};g" \
    -e "s;MAC;${MAC};g" \
    "${SCRIPT_DIR}/../templates/base-jail.conf" >>"/etc/jail.conf.d/${NAME}.conf"
  echo -e "${OPTIONS}\n}" >>"/etc/jail.conf.d/${NAME}.conf"
  if [ "${USE_IPV4}" = "yes" ]; then
    sysrc -R "${BSDINSTALL_CHROOT}" ifconfig_eth0="DHCP"
  fi
  if [ "${USE_IPV6}" = "yes" ]; then
    sysrc -R "${BSDINSTALL_CHROOT}" ifconfig_eth0_ipv6="inet6 -ifdisabled accept_rtadv auto_linklocal"
  fi
fi
