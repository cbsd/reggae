#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

SSHD_FLAGS=`sysrc -n sshd_flags`
SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
CLONED_INTERFACES=`sysrc -n cloned_interfaces`
NATIP=`netstat -rn | awk '/^default/{print $2}'`
EGRESS=`netstat -rn | awk '/^default/{print $4}'`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_INITENV_CONF=`mktemp`
TEMP_RESOLVER_CONF=`mktemp`
ZFS_FEAT="1"

echo "dnsmasq_resolv=/tmp/resolv.conf" >/etc/resolvconf.conf
resolvconf -u
RAW_RESOLVERS=`awk '/^nameserver/{print $2}' /tmp/resolv.conf | tr '\n' ','`
RESOLVERS="${RAW_RESOLVERS%?}"
if [ ! -z `echo "${RESOLVERS}" | grep -o ',$'` ]; then
    RESOLVERS=${RAW_RESOLVERS}
fi

rm -rf /tmp/ifaces.txt
touch /tmp/ifaces.txt
for iface in ${CLONED_INTERFACES}; do
    echo "${iface}" >>/tmp/ifaces.txt
done


LO_INTERFACE=`grep "^${JAIL_INTERFACE}$" /tmp/ifaces.txt`
if [ -z "${LO_INTERFACE}" ]; then
    if [ -z "${CLONED_INTERFACES}" ]; then
        CLONED_INTERFACES="${JAIL_INTERFACE}"
    else
        CLONED_INTERFACES="${CLONED_INTERFACES} ${JAIL_INTERFACE}"
    fi
    sysrc ifconfig_lo1="up"
fi

BRIDGE_INTERFACE=`grep "^${BRIDGE_INTERFACE}$" /tmp/ifaces.txt`
if [ -z "${BRIDGE_INTERFACE}" ]; then
    CLONED_INTERFACES="${CLONED_INTERFACES} ${BRIDGE_INTERFACE}"
    sysrc ifconfig_${BRIDGE_INTERFACE}="inet ${BRIDGE_IP} netmask 255.255.255.0 description ${EGRESS}"
fi

sysrc cloned_interfaces="${CLONED_INTERFACES}"
service netif cloneup
rm -rf /tmp/ifaces.txt


if [ ! -d "${CBSD_WORKDIR}" ]; then
    if [ "${USE_ZFS}" = "yes" ]; then
        ZFSFEAT="1"
        zfs create -o "mountpoint=${CBSD_WORKDIR}" "${ZFS_POOL}${CBSD_WORKDIR}"
    else
        ZFSFEAT="0"
        mkdir "${CBSD_WORKDIR}"
    fi
fi

if [ "${HOSTNAME}" == "${SHORT_HOSTNAME}" ]; then
    HOSTNAME="${SHORT_HOSTNAME}.${DOMAIN}"
    hostname ${HOSTNAME}
    sysrc hostname="${HOSTNAME}"
fi

if [ -z "${SSHD_FLAGS}" ]; then
    sysrc sshd_flags=""
fi

sed \
  -e "s:HOSTNAME:${HOSTNAME}:g" \
  -e "s:NODEIP:${NODEIP}:g" \
  -e "s:RESOLVERS:${RESOLVERS}:g" \
  -e "s:NATIP:${NATIP}:g" \
  -e "s:JAIL_IP_POOL:${JAIL_IP_POOL}:g" \
  -e "s:ZFSFEAT:${ZFSFEAT}:g" \
  ${SCRIPT_DIR}/../templates/initenv.conf >"${TEMP_INITENV_CONF}"

env workdir="${CBSD_WORKDIR}" /usr/local/cbsd/sudoexec/initenv "${TEMP_INITENV_CONF}"
service cbsdd start
service cbsdrsyncd start

cp "${SCRIPT_DIR}/../cbsd-profile/jail-freebsd-reggae.conf" "${CBSD_WORKDIR}/etc/defaults/"
cp -r "${SCRIPT_DIR}/../cbsd-profile/skel" "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel"
cp -r "${SCRIPT_DIR}/../cbsd-profile/system" "${CBSD_WORKDIR}/share/jail-system-reggae"
chown -R root:wheel "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel"
chown -R 666:666 "${CBSD_WORKDIR}/share/FreeBSD-jail-reggae-skel/usr/home/provision"

sed \
  -e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
  -e "s:DOMAIN:${DOMAIN}:g" \
  ${SCRIPT_DIR}/../templates/resolver.conf >"${TEMP_RESOLVER_CONF}"

cbsd jcreate inter=0 jconf="${TEMP_RESOLVER_CONF}"
cat <<EOF >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/named"
named_enable="YES"
EOF
echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/sendmail"
echo 'named_enable="YES"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/named"
cbsd jstart resolver
cp "${SCRIPT_DIR}/../templates/dhclient-exit-hooks" /etc
chmod 700 /etc/dhclient-exit-hooks
if [ ! -f "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key" ]; then
    cbsd jexec jname=resolver rndc-confgen -a -c /usr/local/etc/namedb/cbsd.key -k cbsd
    chown bind:bind "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key"
fi
cp \
    "${SCRIPT_DIR}/../templates/named.conf" \
    "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/named.conf"
cp \
    "${SCRIPT_DIR}/../templates/my.domain" \
    "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/my.domain"
chown bind:bind "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/my.domain"
/etc/dhclient-exit-hooks nohup
cbsd jexec jname=resolver service named restart

cat << EOF >"${CBSD_WORKDIR}/jails-system/resolver/master_poststart.d/add_resolver.sh"
#!/bin/sh
cp "/usr/local/share/reggae/templates/resolvconf.conf" /etc
resolvconf -u
/etc/dhclient-exit-hooks
EOF

cat << EOF >"${CBSD_WORKDIR}/jails-system/resolver/master_prestop.d/remove_resolver.sh"
#!/bin/sh
rm /etc/resolvconf.conf
resolvconf -u
EOF

chmod +x "${CBSD_WORKDIR}/jails-system/resolver/master_poststart.d/add_resolver.sh"
chmod +x "${CBSD_WORKDIR}/jails-system/resolver/master_prestop.d/remove_resolver.sh"

#echo 'jnameserver="127.0.2.1"' > "${TEMP_INITENV_CONF}"
sqlite3 "${CBSD_WORKDIR}/var/db/local.sqlite" "UPDATE local SET jnameserver='127.0.2.1'"
cbsd initenv inter=0 # "${TEMP_INITENV_CONF}"

cp "${SCRIPT_DIR}/../templates/resolvconf.conf" /etc/resolvconf.conf
resolvconf -u

rm -f "${TEMP_INITENV_CONF}" "${TEMP_RESOLVER_CONF}"
