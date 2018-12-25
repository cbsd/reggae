#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
NATIP=`netstat -rn | awk '/^default/{print $2}' | grep '\.'`
EGRESS=`netstat -rn | awk '/^default/{print $4}' | sort | uniq`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_INITENV_CONF=`mktemp`
ZFSFEAT=1


setup_file_system() {
  if [ ! -d "${CBSD_WORKDIR}" ]; then
    if [ "${USE_ZFS}" = "yes" ]; then
      ZFSFEAT=1
      zfs create -o "mountpoint=${CBSD_WORKDIR}" "${ZFS_POOL}${CBSD_WORKDIR}"
    else
      ZFSFEAT=0
      mkdir "${CBSD_WORKDIR}"
    fi
  fi
}


setup_devfs() {
  if [ ! -e "/etc/devfs.rules" -o -z `grep -o 'devfsrules_jail_bpf=7' /etc/devfs.rules` ]; then
    cat << EOF >>/etc/devfs.rules
[devfsrules_jail_bpf=7]
add include \$devfsrules_hide_all
add include \$devfsrules_unhide_basic
add include \$devfsrules_unhide_login
add path 'bpf*' unhide
add path 'pf*' unhide mode 0660 group 136
EOF
    fi
}


setup_cbsd() {
  RESOLVER_BASE=`echo ${JAIL_INTERFACE_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
  JAIL_IP_POOL="${RESOLVER_BASE}.0/24"
  sed \
    -e "s:HOSTNAME:${HOSTNAME}:g" \
    -e "s:NODEIP:${NODEIP}:g" \
    -e "s:JAIL_INTERFACE_IP:${JAIL_INTERFACE_IP}:g" \
    -e "s:NATIP:${NATIP}:g" \
    -e "s:JAIL_IP_POOL:${JAIL_IP_POOL}:g" \
    -e "s:ZFSFEAT:${ZFSFEAT}:g" \
    ${SCRIPT_DIR}/../templates/initenv.conf >"${TEMP_INITENV_CONF}"

  env workdir="${CBSD_WORKDIR}" /usr/local/cbsd/sudoexec/initenv "${TEMP_INITENV_CONF}"
  service cbsdd start
  service cbsdrsyncd start
  sed \
    -e "s/DOMAIN/${DOMAIN}/g" \
    -e "s/JAIL_INTERFACE/${JAIL_INTERFACE}/g" \
    "${SCRIPT_DIR}/../cbsd-profile/jail-freebsd-reggae.conf" >"${CBSD_WORKDIR}/etc/defaults/jail-freebsd-reggae.conf"
  cp -r "${SCRIPT_DIR}/../cbsd-profile/skel" "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel"
  cp -r "${SCRIPT_DIR}/../cbsd-profile/system" "${CBSD_WORKDIR}/share/jail-system-reggae"
  chown -R root:wheel "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel"
  chown -R 666:666 "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel/usr/home/provision"
}


setup_file_system
setup_devfs
setup_cbsd
